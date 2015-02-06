SET SEARCH_PATH = hratky_se_svg, public;

CREATE SEQUENCE id_orp_seq;

CREATE TABLE soubory_slhp(
   id_orp int NOT NULL DEFAULT nextval('id_orp_seq') PRIMARY KEY
   , nazev varchar(255)
);


CREATE FUNCTION f_id_orp() RETURNS BIGINT LANGUAGE SQL AS
$$
SELECT last_value FROM hratky_se_svg.id_orp_seq;
$$
;

CREATE TABLE slhp(
   id_orp int NOT NULL DEFAULT f_id_orp()
   , drevina varchar(255)
   , plocha_ha float
   , plocha_proc float
   , zasoba_m3 float
   , zasoba_proc float
   , avb float
   , stredni_vek float
);


CREATE INDEX ON slhp(id_orp);


