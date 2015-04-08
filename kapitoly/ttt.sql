
SET SEARCH_PATH TO ukol_1, public;

CREATE OR REPLACE VIEW parcely_podle_gridu AS
SELECT row_number() over() id1
, p.*, grid.id grid_id
FROM parcely p, jtsk_grid grid
WHERE p.definicnibod && grid.geom;
