/*
WITH RECURSIVE cte AS (
   SELECT drevina,id_orp, plocha_proc, NULL, NULL, NULL FROM slhp WHERE id_orp = 1 --order by drevina
   UNION ALL
   SELECT cte.*, slhp.drevina,slhp.id_orp, slhp.plocha_proc FROM slhp, cte 
   WHERE 
   slhp.drevina = cte.drevina
   AND slhp.id_orp = cte.id_orp+1 
   
)


SELECT * FROM cte ORDER BY id_orp, drevina;
*/

