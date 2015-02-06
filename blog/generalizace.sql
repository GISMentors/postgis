SET SEARCH_PATH = hratky_se_svg, public, topology;

BEGIN;

SELECT DropTopology('toposka');

SELECT CreateTopology('toposka', 5514, 0);

--SELECT DropTopoGeometryColumn('hratky_se_svg', 'orpecka', 'topogeom');

SELECT AddTopoGeometryColumn('toposka', 'hratky_se_svg', 'orpecka', 'topogeom', 'MULTIPOLYGON');

UPDATE orpecka SET topogeom = toTopoGeom(generalizovanehranice, 'toposka', 1); -- 8.75 seconds




DO $$
   DECLARE a int :=10000;
BEGIN
   LOOP
      BEGIN
	 SELECT ST_ChangeEdgeGeom('toposka', edge_id, ST_SimplifyPreserveTopology(geom, a)) FROM toposka.edge;
	 EXIT;
      EXCEPTION WHEN OTHERS THEN
	 a:=a-1;
      END;

   END LOOP;
END$$;

COMMIT;

/*
-- Simplify all edges up to 10000 units
SELECT SimplifyEdgeGeom('france_dept_topo', edge_id, 10000) FROM france_dept_topo.edge; -- 3.86 seconds

-- Convert the TopoGeometries to Geometries for visualization
ALTER TABLE france_dept ADD geomsimp GEOMETRY;
UPDATE france_dept SET geomsimp = topogeom::geometry; -- 0.11 seconds
*/

