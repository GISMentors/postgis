
SET SEARCH_PATH = hratky_se_svg, public;


\a \t \o orp_jasan_generalizovany_srid_1.svg

SELECT 
XMLELEMENT(NAME svg,
   XMLATTRIBUTES(
   600 AS height
   , 800 AS width
   , array_to_string(ARRAY[MIN(ST_XMIN(generalizovanehranice)) - 2.5, -1 * (MAX(ST_YMAX(generalizovanehranice))) - 2.5
      , (@(MAX(ST_XMAX(generalizovanehranice)) - MIN(ST_XMIN(generalizovanehranice)))) + 5
      , (@(MAX(ST_YMAX(generalizovanehranice)) - MIN(ST_YMIN(generalizovanehranice)))) + 5], ' ') AS "viewBox"
      , 'http://www.w3.org/2000/svg' AS xmlns, '1.1' AS version
   )
   , XMLAGG (
      XMLELEMENT(NAME path,
	 XMLATTRIBUTES(
	    ST_AsSVG(generalizovanehranice, 1, 3) AS d
	    , 'black' AS stroke
	    , 0.3 AS "stroke-width"
	    , 'rgb('||(2.55*(100-(plocha_proc*4)))::int||',255,'||(2.55*(100-(plocha_proc * 4)))::int||')' AS fill
	 )
      ) 
   )
)

FROM (SELECT ST_Transform(topology.ST_Simplify(topogeom, 500) ,1) generalizovanehranice, plocha_proc 
   FROM orpecka o, slhp s
   WHERE o.slhp_id_orp = s.id_orp
   AND drevina = 'jasan'
) g;

\o \a \t
