BEGIN;

SET SEARCH_PATH = hratky_se_svg, public, topology;
/*

SELECT DropTopology('orp_topo');
-- Create a topology
SELECT CreateTopology('orp_topo', 5514, 20); --tady kdyz dam hodne, tak se mi to pokrizi

-- Add a layer
SELECT AddTopoGeometryColumn('orp_topo', 'hratky_se_svg', 'generalizovany_orp', 'topogeom', 'MULTIPOLYGON');
-- Populate the layer and the topology
UPDATE generalizovany_orp SET topogeom = toTopoGeom(ST_SimplifyPreserveTopology(generalizovanehranice, 20), 'orp_topo', 1, 20); -- 8.75 seconds

-- Simplify all edges up to 10000 units
--SELECT SimplifyEdgeGeom('orp_topo', edge_id, 5000) FROM orp_topo.edge; -- 3.86 seconds

-- Convert the TopoGeometries to Geometries for visualization
--ALTER TABLE generalizovany_orp ADD geomsimp geometry('MULTIPOLYGON', 5514);

--DROP TABLE hratky_se_svg.generalizovane_hrany;

--SELECT edge_id, ST_SimplifyPreserveTopology(geom, 50) geom INTO hratky_se_svg.generalizovane_hrany FROM orp_topo.edge;

--UPDATE generalizovany_orp SET topogeom = toTopoGeom(topology.ST_Simplify(topogeom, 500), 'orp_topo', 1);
*/

DROP TABLE generalizovany_polygony;

SELECT slhp_id_orp, topology.ST_Simplify(topogeom, 500) geomsimp INTO hratky_se_svg.generalizovany_polygony FROM generalizovany_orp;


--
/*
DO $$
DECLARE
  tol float8 := 10000;
  sql varchar;
  r record;
BEGIN
   FOR r IN SELECT edge_id FROM orp_topo.edge
      LOOP
	 LOOP
	    sql := 'SELECT topology.ST_ChangeEdgeGeom(''orp_topo'', '||r.edge_id||
	       ', ST_Simplify(geom, ' || tol || '))
	    FROM orp_topo.edge WHERE edge_id = ' || r.edge_id;
	 BEGIN
	    RAISE DEBUG 'Running %', sql;
	    EXECUTE sql;
	    EXIT;
	 EXCEPTION
	    WHEN OTHERS THEN
	       RAISE WARNING 'Simplification of edge % with tolerance % failed: %', r.edge_id, tol, SQLERRM;
	       tol := round( (tol/2.0) * 1e8 ) / 1e8; -- round to get to zero quicker
	       IF tol = 0 THEN RAISE EXCEPTION '%', SQLERRM; END IF;
	    END;
	 END LOOP;
   END LOOP;
END $$;
*/



UPDATE generalizovany_orp SET geomsimp = topogeom::geometry; -- 0.11 seconds



COMMIT;


SET SEARCH_PATH = hratky_se_svg, public;


\a \t \o orp_generalizovane.svg

SELECT 
XMLELEMENT(NAME svg,
   XMLATTRIBUTES(
   600 AS height
   , 800 AS width
   , array_to_string(ARRAY[MIN(ST_XMIN(geomsimp)) - 3, -1 * (MAX(ST_YMAX(geomsimp))) - 3
      , (@(MAX(ST_XMAX(geomsimp)) - MIN(ST_XMIN(geomsimp)))) + 6
      , (@(MAX(ST_YMAX(geomsimp)) - MIN(ST_YMIN(geomsimp)))) + 6], ' ') AS "viewBox"
      , 'http://www.w3.org/2000/svg' AS xmlns, '1.1' AS version
   )
   , XMLAGG (
      XMLELEMENT(NAME path,
	 XMLATTRIBUTES(
	    ST_AsSVG(geomsimp, 0, 0) AS d
	    , 'black' AS stroke
	    , 0.3 AS "stroke-width"
	    , 'rgb('||(2.55*(100-(plocha_proc*4)))::int||',255,'||(2.55*(100-(plocha_proc * 4)))::int||')' AS fill
	 )
      ) 
   )
)

from (SELECT ST_Transform(geomsimp, 1) geomsimp, plocha_proc 
   FROM generalizovany_polygony o, slhp s
   WHERE o.slhp_id_orp = s.id_orp
   AND drevina = 'jasan') g;

\o \a \t
