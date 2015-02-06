SET SEARCH_PATH = hratky_se_svg, public;


\a \t 
--\o orp_podle_css.svg

SELECT xmlpi(name "xml-stylesheet", 'type="text/css" href="jasan.css"');

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
   , XMLAGG (
      XMLELEMENT(NAME path,
	 XMLATTRIBUTES(
	    'orp_' || slhp_id_orp AS id
	    , ST_AsSVG(generalizovanehranice, 0, 0) AS d
	    , 'black' AS stroke
	    , 300 AS "stroke-width"
	    , 'none' AS fill
	    --, 'rgb('||(2.55*(100-(plocha_proc*4)))::int||',255,'||(2.55*(100-(plocha_proc * 4)))::int||')' AS fill
	 )
      ) 
   )
)

FROM orpecka o;

\o jasan.css

SELECT 
'#orp_'||id_orp||
' {fill:rgb('|| (255*((30-plocha_proc)/30))::int||',255,'|| 
   (255*((30-plocha_proc)/30))::int||');}' from slhp where drevina = 'jasan';


\o lipa.css
SELECT 
'#orp_'||id_orp||
' {fill:rgb('|| (255*((20-plocha_proc)/20))::int||',255,'|| 
   (255*((20-plocha_proc)/20))::int||');}' from slhp where drevina = 'lípa';

\o smrk.css
SELECT 
'#orp_'||id_orp||
' {fill:rgb('|| (255*((80-plocha_proc)/80))::int||',255,'|| 
   (255*((80-plocha_proc)/80))::int||');}' from slhp where drevina = 'smrk ztepilý';

\o \a \t
