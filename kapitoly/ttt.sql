SET SEARCH_PATH TO ukol_1, public;

CREATE TABLE jtsk_grid AS
WITH RECURSIVE
bb AS (
   SELECT ST_Extent(originalnihranice) bbgeom FROM budovy
)
, x AS (
   SELECT ST_XMin(bbgeom) a FROM bb
   UNION
   SELECT a + 1000 FROM x WHERE a < (SELECT ST_XMax(bbgeom) FROM bb)
)
, y AS (
   SELECT ST_YMin(bbgeom) a FROM bb
   UNION
   SELECT a + 1000 FROM y WHERE a < (SELECT ST_YMax(bbgeom) FROM bb)
)
SELECT 
row_number() over() id
, x.a x, y.a y
, ST_SetSRID(
   ST_Envelope(
      ST_UNION(ST_MakePoint(x.a, y.a, 5514)
	 , ST_MakePoint(x.a + 1000, y.a + 1000, 5514)
      )
   ), 5514
)::geometry(POLYGON, 5514) geom FROM x, y;
