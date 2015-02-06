SELECT 
row_number() over(order by a.slhp_id_orp, b.slhp_id_orp) id
, MULTI(ST_AsText(ST_CollectionExtract(ST_Intersection(a.geomsimp, b.geomsimp), 3))) geom
FROM hratky_se_svg.generalizovany_polygony a, hratky_se_svg.generalizovany_polygony b 
WHERE a.geomsimp && b.geomsimp
AND ST_Relate (a.geomsimp, b.geomsimp, '2********');

SELECT 
row_number() over(order by a.slhp_id_orp, b.slhp_id_orp) id
, MULTI(ST_AsText(ST_CollectionExtract(ST_Intersection(a.geom, b.geom), 3))) geom
FROM hratky_se_svg.generalizovany_orp a, hratky_se_svg.generalizovany_orp b 
WHERE a.geom && b.geom
AND ST_Relate (a.geom, b.geom, '2********');

SELECT 
row_number() over(order by a.slhp_id_orp, b.slhp_id_orp) id
, MULTI(ST_AsText(ST_CollectionExtract(ST_Intersection(a.geom, b.geom), 3))) geom
FROM hratky_se_svg.generalizovany_orp a, hratky_se_svg.generalizovany_orp b 
WHERE a.geom && b.geom
AND ST_Relate (a.geom, b.geom, '2********')
AND a.slhp_id_orp != b.slhp_id_orp
