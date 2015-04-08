===============
Efektivní práce
===============

UDF funkce
==========

Funkce vytváříme příkazem :pgsqlcmd:`CREATE FUNCTION 
<sql-createfunction>`. Funkce může být napsaná přímo v jazyce `SQL`, v 
procedurálním jazyce PostgreSQL `PL/pgSQL`, případně v jednom z jazyků,
které podopruje PostgreSQL.

Ukažme si jednoduchý příklad funkce, která vrací kolik procent polygonu
je zakryto druhým polygonem.

.. code-block:: sql

   CREATE OR REPLACE FUNCTION procento_prekryvu(geometry, geometry) 
   RETURNS float AS $fbody$
      SELECT
      (
         ST_Area(ST_Intersection($1, $2))/
         ST_Area($1)
      ) * 100;
   $fbody$
   LANGUAGE SQL;

   SELECT procento_prekryvu(
      ST_Buffer(ST_MakePoint(0,0), 50),
      ST_Buffer(ST_MakePoint(50,0), 25));

.. noteadvanced:: U funkcí v PostgreSQL funguje přetěžování proměnných, takže
   je možné napsat celou řadu funkcí pro různé kombinace proměnných.

Složitější funkci si ukážeme v Pl/pgSQL. Bude se jmenovat `šupiny` a bude vracet
polygon oříznutý o části, které jsou zakryté polygony v tabulce šupiny.

.. code-block:: sql


   BEGIN;

   CREATE TABLE supiny (
      id SERIAL PRIMARY KEY
      , geom geometry(POLYGON, 0)
   );

   CREATE OR REPLACE FUNCTION supiny(sup geometry) 
   RETURNS geometry AS $$
   DECLARE 
   odecist geometry;
   BEGIN
      odecist := ST_MemUnion(geom) FROM supiny
      --normální UNION zlobí kvůli topologickým chybám
      WHERE geom && sup;
      /* vyfiltruji prvky z okoli zajmoveho uzemi*/
      IF odecist IS NULL THEN --odecist je prazdny
         RETURN sup;
      ELSE
         RETURN 
            ST_CollectionExtract(ST_Difference(sup, odecist),3)
            ;
         /* Collection extract vybere pouze polygony*/
      END IF;

   END;
   $$ LANGUAGE plpgsql;

   --vygeneruji náhodná data

   DO $$
      DECLARE i int;
      BEGIN
         FOR i in 1..500 LOOP
            INSERT INTO supiny(geom)
            SELECT (ST_Dump(
                  supiny(
                     ST_Buffer(
                        ST_Point(
                           random() * 100
                           , random() * 100
                     ), (random() * 10) + 10
                     , 25
                  )
               )
            )).geom;
         END LOOP;
      END
      $$;



   COMMIT;


.. figure:: ../images/supiny.png



Common table expression
=======================

:pgsqlcmd:`Common table expression <queries-with>`. Má hned několik 
zajímavých vlastností. Tou první je možnost rekurze. To je možné využít
například při generování čtvercové sítě, nebo generování hierarchických
struktur.

Použití rekruzivního :sqlcmd:`CTE` si předvedeme v následujícím příkladu.

	
.. code-block:: sql

   SET SEARCH_PATH TO ukol_1, public;

   CREATE TABLE jtsk_grid AS
   WITH RECURSIVE
   bb AS (
      SELECT ST_Extent(originalnihranice) bbgeom FROM budovy
   )
   , x AS (
      SELECT ST_XMin(bbgeom) a FROM bb
      UNION
      SELECT a + 1000 FROM x WHERE a < (SELECT ST_XMax(bbgeom) FROM bb)
   )
   , y AS (
      SELECT ST_YMin(bbgeom) a FROM bb
      UNION
      SELECT a + 1000 FROM y WHERE a < (SELECT ST_YMax(bbgeom) FROM bb)
   )
   SELECT 
   row_number() over() id
   , x.a x, y.a y
   , ST_SetSRID(
      ST_Envelope(
         ST_UNION(ST_MakePoint(x.a, y.a, 5514)
            , ST_MakePoint(x.a + 1000, y.a + 1000, 5514)
         )
      ), 5514
   )::geometry(POLYGON, 5514) geom FROM x, y;

.. noteadvanced:: Místo rekurzivního cte lze v tomto příkladu použít
   generate_series s týmž výsledkem.

Dotaz můžeme pustit přímo z db manageru QGISu.

.. figure:: ../images/db_manager_cte.png

.. figure:: ../images/jtsk_grid.png

Anonymní blok kódu
==================

Nerelační typy
==============

Pohledy
=======
