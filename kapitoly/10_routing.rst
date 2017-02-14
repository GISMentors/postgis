Síťové analýzy
==============

Síťové analýzy (tzv. routing) zajišťuje v prostředí PostGIS nastavba
označovaná jako `pgRouting <http://pgrouting.org/>`__. Nadstavba se v
databázi aktivuje příkazem:

.. code-block:: sql

   create extension pgrouting;

Příprava dat
------------

Jako podkladová data použijeme data OpenStreetMap pro území Hlavního
města Praha. Tato data stáhneme přes tzv. Overpass API. Území je dáno
minimálním ohraničujícím obdélníkem (bbox), který můžeme zjistit
např. ze stránek http://boundingbox.klokantech.com (formát CSV).

Příklad stažení dat:

.. code-block:: bash
                
   wget --progress=dot:mega -O praha.osm \
   "http://www.overpass-api.de/api/xapi?*[bbox=14.224435,49.941898,14.706787,50.177433][@meta]"

Data naimportujeme do databáze *gismentors*, nejrpve založíme nové
schéma:

.. code-block:: sql

   create schema routing;

Import dat zajišťuje specializovaný nástroj :program:`osm2routing`,
příklad volání:

.. code-block:: bash

   osm2pgrouting -f praha.osm --schema routing -d gismentors -U postgres

Po importu se ve výstupním schématu objeví následující tabulky:

.. code-block:: sql

   select f_table_name,f_geometry_column,coord_dimension,srid,type
   from geometry_columns where f_table_schema = 'routing';

::
   
   f_table_name    | f_geometry_column | coord_dimension | srid |    type    
   -------------------+-------------------+-----------------+------+------------
   osm_nodes         | the_geom          |               2 | 4326 | POINT
   ways_vertices_pgr | the_geom          |               2 | 4326 | POINT
   ways              | the_geom          |               2 | 4326 | LINESTRING

.. note:: Jak je vidět tak jsou data transformována do WGS-84
          (:epsg:`4326`), geometrie je uložena ve sloupci
          :dbcolumn:`the_geom`. Pro zachování konzistence v databáze
          jej přejmenujeme na :dbcolumn:`geom`.

          .. code-block:: sql

             alter table routing.osm_nodes rename the_geom to geom;
             alter table routing.ways_vertices_pgr rename the_geom to geom;
             alter table routing.ways rename the_geom to geom;

Nalezení optimální cesty
------------------------

Algoritmus nalezení optimální cesty je implementován v pgRouting ve
třech variantách:

* `pgr_dijkstra
  <http://docs.pgrouting.org/latest/en/src/dijkstra/doc/pgr_dijkstra.html>`__,
  viz. :wikipedia-en:`Dijkstra's algorithm`
* `pgr_dijkstraCost
  <http://docs.pgrouting.org/latest/en/src/dijkstra/doc/pgr_dijkstraCost.html>`__
* `pgr_astar
  <http://docs.pgrouting.org/latest/en/src/astar/doc/pgr_astar.html#description>`__,
  viz :wikipedia-en:`A* search algorithm`

V následujících příkladech se bude pohybovat v okolí Fakulty stavební
ČVUT v Praze, kde školení GISMentors většinou probíhají:
http://www.openstreetmap.org/#map=16/50.1029/14.3912

Příklad 1
^^^^^^^^^

Dijkstrův algoritmus vyžaduje definovat celkem čtyři atributy:

* `id` - ID uzlu 
* source - ID počátečního uzlu
* target - ID koncového uzlu
* cost - atribut nákladů

Nejkratší trasa (jeden chodec)
~~~~~~~~~~~~~~~

Chodec se pohybuje ze stanice metra Dejvická (``osm_id: 2911015007``) k
budově Fakulty stavební ČVUT v Praze (``osm_id: 2905257304``). Hledáme
nejkratší trasu, nákladem tedy bude *délka* segmentů trasy. Chodec se
může pohybovat ve všech směrech (budeme pracovat s neorientovaným
grafem).

Zjistíme ID uzlů v rámci grafu:

.. code-block:: sql

   SELECT osm_id, id FROM ways_vertices_pgr
   WHERE osm_id IN (2911015007, 2905257304);

::

      osm_id   |  id   
   ------------+-------
    2911015007 |  1594
    2905257304 | 10824


Nejkratší trasu nalezneme voláním funkce `pgr_dijkstra
<http://docs.pgrouting.org/latest/en/src/dijkstra/doc/pgr_dijkstra.html>`__:

.. code-block:: sql
                
   SELECT * FROM pgr_dijkstra('
    SELECT gid AS id,
    source,
    target,
    length AS cost
    FROM ways',
   1594, 10824, directed := false);

::

    seq | path_seq |  node  |  edge  |         cost         |       agg_cost       
   -----+----------+--------+--------+----------------------+----------------------
      1 |        1 |  1594 | 137005 |  9.9040395796202e-06 |                    0
      2 |        2 | 88646 |  71297 | 0.000129719697808577 | 9.90403957962019e-06
   ...
     24 |       24 |  1164 |  31277 |  6.8521529463256e-05 |  0.00684939507573181
     25 |       25 | 10824 |     -1 |                    0 |  0.00691791660519507

.. note:: Náklady jsou počítany v mapových jednotkách souřadnicového
          systému, v tomto případě stupních. Délku v metrech získáme
          pomocí atributu :dbcolumn:`length_m`. Příklad výpočtu
          celkové délky nalezené trasy:

          .. code-block:: sql
                          
             select sum(cost) from (SELECT * FROM pgr_dijkstra('
              SELECT gid AS id,
              source,
              target,
              length_m AS cost
              FROM ways',
             1594, 10824, directed := false)) as foo;

          ::
             
             sum        
             ------------------
             578.522948228576

.. tip:: Pokud si přejete místo sumarizační tabulky získat geometrii
         nalezené trasy, tak příkaz mírně upravíte.

         .. code-block:: sql
                         
             SELECT a.*, ST_AsText(b.geom) FROM pgr_dijkstra('
              SELECT gid AS id,
              source,
              target,
              length_m AS cost
              FROM ways',
             1594, 10824, directed := false) as a
             LEFT JOIN ways as b
             ON (a.edge = b.gid) ORDER BY seq;
                    

         .. figure:: ../images/route-single.png

            Vizualizace nalezené nejkratší trasy.
            
Další materiály
---------------

* http://workshop.pgrouting.org
