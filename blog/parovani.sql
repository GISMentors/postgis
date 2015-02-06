ALTER TABLE orpecka ADD slhp_id_orp int;

UPDATE orpecka o SET slhp_id_orp = id_orp
FROM soubory_slhp s WHERE o.nazev =  regexp_replace(s.nazev, 'ORP \d{4} \- ','');
