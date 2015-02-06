
DECLARE
  boundary GEOMETRY;
  fgeom GEOMETRY;
  rec RECORD;
  edges INTEGER[];
  sql TEXT;
  tol FLOAT8;
BEGIN

  -- 0. Check arguments
  IF geometrytype(apoly) != 'POLYGON' THEN
    RAISE EXCEPTION 'Invalid geometry type (%) passed to TopoGeo_AddPolygon, expected POLYGON', geometrytype(apoly);
  END IF;

  -- Get tolerance, if 0 was given
  tol := COALESCE( NULLIF(tolerance, 0), topology._st_mintolerance(atopology, apoly) );

  -- 1. Extract boundary
  boundary := ST_Boundary(apoly);

  -- 2. Add boundaries as edges
  FOR rec IN SELECT (ST_Dump(boundary)).geom LOOP
    edges := array_cat(edges, array_agg(x)) FROM ( select topology.TopoGeo_addLinestring(atopology, rec.geom, tol) as x ) as foo;
  END LOOP;

  -- 3. Find faces covered by input polygon
  --    NOTE: potential snapping changed polygon edges
  sql := 'SELECT DISTINCT f.face_id FROM ' || quote_ident(atopology)
    || '.face f WHERE f.mbr && '
    || quote_literal(apoly::text)
    || '::geometry';
  FOR rec IN EXECUTE sql LOOP
    -- check for actual containment
    fgeom := ST_PointOnSurface(ST_GetFaceGeometry(atopology, rec.face_id));
    IF NOT ST_Covers(apoly, fgeom) THEN
      CONTINUE;
    END IF;
    RETURN NEXT rec.face_id;
  END LOOP;

END

