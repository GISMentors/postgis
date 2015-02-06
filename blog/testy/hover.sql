
SET SEARCH_PATH = hratky_se_svg, public;


\a \t \o orp_jasan_generalizovany_hover.svg

SELECT xmlpi(name "xml-stylesheet", 'type="text/css" href="orp_jasan_generalizovany_hover.css"');

SELECT 
XMLELEMENT(NAME svg,
   XMLATTRIBUTES(
   600 AS height
   , 800 AS width
   , array_to_string(ARRAY[MIN(ST_XMIN(generalizovanehranice)) - 2500, -1 * (MAX(ST_YMAX(generalizovanehranice))) - 2500
      , (@(MAX(ST_XMAX(generalizovanehranice)) - MIN(ST_XMIN(generalizovanehranice)))) + 5000
      , (@(MAX(ST_YMAX(generalizovanehranice)) - MIN(ST_YMIN(generalizovanehranice)))) + 5000], ' ') AS "viewBox"
      , 'http://www.w3.org/2000/svg' AS xmlns, '1.1' AS version
   )
   --, XMLELEMENT(NAME g, XMLATTRIBUTES('mapa' AS class)
      , XMLAGG (
	 XMLELEMENT(NAME path,
	    XMLATTRIBUTES(
	       'orp_'||id_orp AS class
	       , ST_AsSVG(generalizovanehranice, 1, 0) AS d
	       , 'black' AS stroke
	       , 300 AS "stroke-width"
	       , 'rgb('||(2.55*(100-(plocha_proc*4)))::int||',255,'||(2.55*(100-(plocha_proc * 4)))::int||')' AS fill
	    )
	 ) 
      )
   --)
   --, XMLELEMENT(NAME g, XMLATTRIBUTES('popisky' AS class)
      , XMLAGG(
	 XMLPARSE(content '<text class="orp_'||id_orp::text||'" text-anchor="middle" font-family="Verdana" fill="black" font-size="10000" display="none" '
	       ||ST_AsSVG(ST_Centroid(generalizovanehranice),1)||'>'||nazev||'</text>') 
      )
   --)

)

FROM (SELECT topology.ST_Simplify(topogeom, 500) generalizovanehranice, plocha_proc, slhp_id_orp id_orp, nazev
   FROM orpecka o, slhp s
   WHERE o.slhp_id_orp = s.id_orp
   AND drevina = 'jasan'
) g;

\o  popisky.css
SELECT '.orp_'||slhp_id_orp||':hover ~ '||'.orp_'||slhp_id_orp||' {display:inline;}' FROM orpecka;

\o \a \t

