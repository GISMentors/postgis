
DECLARE
  rec RECORD;
  rec2 RECORD;
  sql TEXT;
  set1 GEOMETRY;
  set2 GEOMETRY;
  snapped GEOMETRY;
  noded GEOMETRY;
  start_node INTEGER;
  end_node INTEGER;
  id INTEGER; 
  inodes GEOMETRY;
  iedges GEOMETRY;
  tol float8;
BEGIN

  -- 0. Check arguments
  IF geometrytype(aline) != 'LINESTRING' THEN
    RAISE EXCEPTION 'Invalid geometry type (%) passed to TopoGeo_AddLinestring, expected LINESTRING', geometrytype(aline);
  END IF;

  -- Get tolerance, if 0 was given
  tol := COALESCE( NULLIF(tolerance, 0), topology._st_mintolerance(atopology, aline) );

  -- 1. Self-node
  noded := ST_UnaryUnion(aline);

  -- 2. Node to edges falling within tol distance
  sql := 'WITH nearby AS ( SELECT e.geom FROM '
    || quote_ident(atopology) 
    || '.edge e WHERE ST_DWithin(e.geom, '
    || quote_literal(noded::text)
    || '::geometry, '
    || tol || ') ) SELECT st_collect(geom) FROM nearby;';
  EXECUTE sql INTO iedges;
  IF iedges IS NOT NULL THEN


    snapped := ST_Snap(noded, iedges, tol);

    noded := ST_Difference(snapped, iedges);

    set1 := ST_Intersection(snapped, iedges);

    set2 := ST_LineMerge(set1);

    noded := ST_Union(noded, set2);

  END IF;

  -- 2.1. Node with existing nodes within tol
  -- TODO: check if we should be only considering _isolated_ nodes!
  sql := 'WITH nearby AS ( SELECT n.geom FROM '
    || quote_ident(atopology) 
    || '.node n WHERE ST_DWithin(n.geom, '
    || quote_literal(noded::text)
    || '::geometry, '
    || tol || ') ) SELECT st_collect(geom) FROM nearby;';
  EXECUTE sql INTO inodes;

  IF inodes IS NOT NULL THEN -- {

    -- TODO: consider snapping once against all elements
    ---      (rather than once with edges and once with nodes)
    noded := ST_Snap(noded, inodes, tol);

    FOR rec IN SELECT (ST_Dump(inodes)).geom
    LOOP
        -- Use the node to split edges
        SELECT ST_Collect(geom) 
        FROM ST_Dump(ST_Split(noded, rec.geom))
        INTO STRICT noded;
    END LOOP;

    -- re-node to account for ST_Snap introduced self-intersections
    -- See http://trac.osgeo.org/postgis/ticket/1714
    -- TODO: consider running UnaryUnion once after all noding 
    noded := ST_UnaryUnion(noded);
  END IF; -- }

  -- 3. For each (now-noded) segment, insert an edge
  FOR rec IN SELECT (ST_Dump(noded)).geom LOOP

    -- TODO: skip point elements ?


    start_node := topology.TopoGeo_AddPoint(atopology,
                                          ST_StartPoint(rec.geom),
                                          tol);

    end_node := topology.TopoGeo_AddPoint(atopology,
                                        ST_EndPoint(rec.geom),
                                        tol);

    -- Added endpoints may have drifted due to tolerance, so
    -- we need to re-snap the edge to the new nodes before adding it
    sql := 'SELECT n1.geom as sn, n2.geom as en FROM ' || quote_ident(atopology)
      || '.node n1, ' || quote_ident(atopology)
      || '.node n2 WHERE n1.node_id = '
      || start_node || ' AND n2.node_id = ' || end_node;

    EXECUTE sql INTO STRICT rec2;

    snapped := ST_SetPoint(
                 ST_SetPoint(rec.geom, ST_NPoints(rec.geom)-1, rec2.en),
                 0, rec2.sn);

    
    snapped := ST_CollectionExtract(ST_MakeValid(snapped), 2);


    -- Check if the so-snapped edge collapsed (see #1650)
    IF ST_IsEmpty(snapped) THEN
      CONTINUE;
    END IF;

    -- Check if the so-snapped edge _now_ exists
    sql := 'SELECT edge_id FROM ' || quote_ident(atopology)
      || '.edge_data WHERE ST_Equals(geom, ' || quote_literal(snapped::text)
      || '::geometry)';
    EXECUTE sql INTO id;
    IF id IS NULL THEN
      id := topology.ST_AddEdgeModFace(atopology, start_node, end_node,
                                       snapped);
    ELSE
    END IF;

    RETURN NEXT id;

  END LOOP;

  RETURN;
END

