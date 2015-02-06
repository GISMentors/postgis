--SET SEARCH_PATH = hratky_se_svg, public;

/*
SELECT 'SELECT drevina, '||
array_to_String(array_agg('SUM(CASE WHEN id_orp = '||id_orp||' THEN plocha_proc ELSE 0 END) orp_'||id_orp ORDER BY id_orp), ', ')||
' FROM slhp GROUP BY drevina ORDER BY drevina'
FROM
(
   SELECT DISTINCT id_orp FROM slhp ORDER BY id_orp
) id_orp
;
*/

DO $$DECLARE qt text;
BEGIN
   qt :='CREATE TABLE tmp AS SELECT drevina, '||
      array_to_String(array_agg('SUM(CASE WHEN id_orp = '||id_orp||' THEN plocha_proc ELSE 0 END) orp_'||id_orp ORDER BY id_orp), ', ')||
      ' FROM slhp GROUP BY drevina ORDER BY drevina'
      FROM
      (
	 SELECT DISTINCT id_orp FROM slhp ORDER BY id_orp
      ) id_orp
      ;

      EXECUTE qt;
END$$;

SELECT * FROM tmp;
