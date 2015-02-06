
BEGIN;

SET SEARCH_PATH = hratky_se_svg, public, topology;

SELECT DropTopology('orp_topo_2');
-- Create a topology
SELECT CreateTopology('orp_topo_2', 5514, 20); --tady kdyz dam hodne, tak se mi to pokrizi

-- Add a layer
SELECT AddTopoGeometryColumn('orp_topo_2', 'hratky_se_svg', 'generalizovany_orp', 'topogeom_2', 'MULTIPOLYGON');
-- Populate the layer and the topology
--UPDATE generalizovany_orp SET topogeom_2 = toTopoGeom(topology.ST_Simplify(topogeom, 500), 'orp_topo_2', 2);
--DROP TABLE hratky_se_svg.generalizovane_hrany;

--SELECT edge_id, ST_SimplifyPreserveTopology(geom, 50) geom INTO hratky_se_svg.generalizovane_hrany FROM orp_topo.edge;

UPDATE generalizovany_orp SET topogeom = toTopoGeom(topology.ST_Simplify(topogeom, 500), 'orp_topo', 1);

COMMIT;
