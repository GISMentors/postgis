CREATE OR REPLACE FUNCTION geom_z_xy() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $BODY$ 
BEGIN
   NEW.geom_p := 'SRID=5514;POINT('||NEW.x::text||' '||NEW.y::text||')';
   RETURN NEW;
END;
$BODY$;

CREATE TRIGGER geom_z_xy 
BEFORE INSERT OR UPDATE ON vesmirne_zrudice
FOR EACH ROW EXECUTE PROCEDURE geom_z_xy();

TRUNCATE vesmirne_zrudice;

\copy vesmirne_zrudice (id, x, y) FROM jelen_dta/gismentors/postgis/data/body.csv

SELECT *, ST_AsText(geom_p), ST_SRID(geom_p) FROM vesmirne_zrudice;
