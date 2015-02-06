SET SEARCH_PATH = hratky_se_svg, public;

SELECT pp_json(('{'||array_to_string(array_agg('"'||drevina||'":'||orp),', ')||'}')::json)
FROM
(
   SELECT
   drevina, ('{'||array_to_string(array_agg('"orp_'||id_orp||'":'||plocha_proc),', ')||'}') orp
   FROM
   (
      SELECT 
      drevina
      , id_orp
      , avg(plocha_proc) plocha_proc
      FROM slhp 
      --WHERE avb IS NOT NULL 
      GROUP BY id_orp, drevina
   ) dta
   GROUP BY drevina
) orp
;
