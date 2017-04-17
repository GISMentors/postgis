Síťové analýzy
==============

Síťové analýzy (tzv. routing) zajišťuje v prostředí PostGIS nadstavba
označovaná jako `pgRouting <http://pgrouting.org/>`__. Tuto nadstavbu
v databázi aktivujeme příkazem:

.. code-block:: sql

   CREATE EXTENSION pgrouting;

Příprava dat
------------

Jako podkladová data použijeme data OpenStreetMap pro území Hlavního
města Prahy. Data stáhneme přes tzv. Overpass API. Území je dáno
minimálním ohraničujícím obdélníkem (bbox), který můžeme zjistit
např. ze stránek http://boundingbox.klokantech.com (formát CSV).

Příklad stažení dat:

.. code-block:: bash
                
   wget --progress=dot:mega -O praha.osm \
   "http://www.overpass-api.de/api/xapi?*[bbox=14.224435,49.941898,14.706787,50.177433][@meta]"

Data naimportujeme do databáze *gismentors*. Import dat zajišťuje
specializovaný nástroj :program:`osm2routing`, příklad volání:

.. code-block:: bash

   osm2pgrouting -f praha.osm --schema routing -d gismentors -U postgres

Po importu se ve výstupním schématu objeví následující tabulky:

.. code-block:: sql

   SELECT f_table_name,f_geometry_column,coord_dimension,srid,type
   FROM geometry_columns WHERE f_table_schema = 'routing';

::
   
      f_table_name    | f_geometry_column | coord_dimension | srid |    type    
   -------------------+-------------------+-----------------+------+------------
    osm_nodes         | the_geom          |               2 | 4326 | POINT
    ways_vertices_pgr | the_geom          |               2 | 4326 | POINT
    ways              | the_geom          |               2 | 4326 | LINESTRING

.. note:: Jak je vidět tak jsou data transformována do
          :skoleni:`WGS-84 <open-source-gis/soursystemy/wgs84.html>`
          (:epsg:`4326`), geometrie je uložena ve sloupci
          :dbcolumn:`the_geom`. Pro zachování konzistence v databáze
          jej přejmenujeme na :dbcolumn:`geom`.

          .. code-block:: sql

             ALTER TABLE osm_nodes RENAME the_geom TO geom;
             ALTER TABLE ways_vertices_pgr RENAME the_geom TO geom;
             ALTER TABLE ways RENAME the_geom TO geom;

Nalezení optimální cesty
------------------------

Algoritmus nalezení optimální cesty je implementován v pgRouting ve
dvou variantách:

* `pgr_dijkstra
  <http://docs.pgrouting.org/latest/en/src/dijkstra/doc/pgr_dijkstra.html>`__,
  viz. :wikipedia-en:`Dijkstra's algorithm`
* `pgr_astar
  <http://docs.pgrouting.org/latest/en/src/astar/doc/pgr_astar.html#description>`__,
  viz :wikipedia-en:`A* search algorithm`

.. note:: V následujících příkladech se bude pohybovat v okolí Fakulty stavební
   ČVUT v Praze, kde školení GISMentors většinou probíhají:
   http://www.openstreetmap.org/#map=16/50.1029/14.3912

Příklad - chodec
^^^^^^^^^^^^^^^^

Nejkratší trasa (jeden chodec)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Chodec se pohybuje ze stanice metra Dejvická (``osm_id: 2911015007``)
k budově Fakulty stavební ČVUT v Praze (``osm_id:
2905257304``). Hledáme nejkratší trasu, nákladem tedy bude *délka*
segmentů trasy. Chodec se může pohybovat v obou směrech (budeme
pracovat s neorientovaným grafem).

Zjistíme ID uzlů v rámci grafu:

.. code-block:: sql

   SELECT osm_id, id FROM ways_vertices_pgr
   WHERE osm_id IN (2911015007, 2905257304);

::

      osm_id   |  id   
   ------------+-------
    2911015007 |  1594
    2905257304 | 10824

Výchozí a cílový bod můžeme také najít s využitím adresních míst RǓIAN.
Dojde k vyhledání všech OSM bodů do vzdálenosti 10 m od zadané adresy.

Nastavíme si cestu ke schématům.

.. code-block:: sql
   
   SET search_path TO public,routing,ruian_praha;

.. code-block:: sql

   SELECT o.osm_id, o.id, a.gml_id FROM 
   ruian_praha.adresnimista a, 
   ruian_praha.ulice u, 
   routing.ways_vertices_pgr o 
   WHERE a.cisloorientacni = 1 AND u.nazev = 'Šolínova' 
   AND a.ulicekod = u.kod 
   AND ST_DWithin(ST_Transform(o.geom, 5514), a.geom, 10);

::

      osm_id   |   id   |   gml_id    
   ------------+--------+-------------
      55320587 |  79643 | AD.22189076
    1249805116 |  87127 | AD.22189076
    1249805175 | 120172 | AD.22189076   
    1249805047 | 149722 | AD.22189076
 
.. code-block:: sql

   SELECT o.osm_id, o.id, a.gml_id FROM 
   ruian_praha.adresnimista a, 
   ruian_praha.ulice u, 
   routing.ways_vertices_pgr o 
   WHERE a.cisloorientacni = 5 AND u.nazev = 'Technická' 
   AND a.ulicekod = u.kod 
   AND ST_DWithin(ST_Transform(o.geom, 5514), a.geom, 10);

::

      osm_id   |   id   |   gml_id    
   ------------+--------+-------------
    2905214176 | 129632 | AD.22207996
    2905214180 | 146959 | AD.22207996


Nejkratší trasu nalezneme voláním funkce `pgr_dijkstra
<http://docs.pgrouting.org/latest/en/src/dijkstra/doc/pgr_dijkstra.html>`__. Dijkstrův
algoritmus vyžaduje definovat celkem čtyři atributy:

* `id` - identifikátor hrany
* source - identifikátor počátečního uzlu
* target - identifikátor koncového uzlu
* cost - atribut nákladů

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

Náklady jsou počítány v mapových jednotkách souřadnicového systému, v
tomto případě stupních. Délku v metrech je uložena v atributu
:dbcolumn:`length_m`. Příklad výpočtu celkové délky nalezené trasy:

.. code-block:: sql
                          
   SELECT sum(cost) FROM (SELECT * FROM pgr_dijkstra('
    SELECT gid AS id,
    source,
    target,
    length_m AS cost
    FROM ways',
   1594, 10824, directed := false)) AS foo;

::
             
   sum        
   ------------------
   578.522948228576

Geometrii trasy získáte spojením výsledku hledání optimální trasy s
původní tabulkou:

.. code-block:: sql
                         
   SELECT a.*, ST_AsText(b.geom) FROM pgr_dijkstra('
    SELECT gid AS id,
    source,
    target,
    length_m AS cost
    FROM ways',
    1594, 10824, directed := false) AS a
   LEFT JOIN ways AS b
   ON (a.edge = b.gid) ORDER BY seq;

.. figure:: ../images/route-single.png
   :class: small
   
   Vizualizace nalezené nejkratší trasy.

.. note:: Pro hledání optimální trasy lze použít funkci `pgr_astar
  <http://docs.pgrouting.org/latest/en/src/astar/doc/pgr_astar.html#description>`__,
  která pracuje s geografickou informací uzlů hran grafu. To umožňuje
  ve výpočtu preferovat hrany, které jsou blíže cíle trasy.

  .. code-block:: sql

     SELECT * FROM pgr_astar('
      SELECT gid AS id,
      source,
      target,
      length AS cost,
      x1, y1, x2, y2
      FROM ways',
     1594, 10824, directed := false);

Nejkratší trasa (více chodců, jeden cíl)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Chodci se pohybují ze stanice metra Dejvická (``osm_id: 2911015007``),
Hradčanská (``osm_id: 1990839852``) a nádraží Dejvice (``osm_id:
4196659626``) k budově Fakulty stavební ČVUT v Praze (``osm_id:
2905257304``).

.. code-block:: sql

   SELECT osm_id, id FROM ways_vertices_pgr
   WHERE osm_id IN (2911015007, 1990839852, 4196659626, 2905257304);

::

      osm_id   |  id   
   ------------+-------
    2911015007 |   1594
    1990839852 |  99683
    4196659626 | 141866
    2905257304 |  10824

.. code-block:: sql
                
   SELECT * FROM pgr_dijkstra('
    SELECT gid AS id,
    source,
    target,
    length AS cost
    FROM ways',
   ARRAY[1594, 99683, 141866], 10824, directed := false);

.. figure:: ../images/route-multi.png

   Vizualizace nalezených nejkratších cest (cíl je znázorněn zelenou
   barvou).

Nejrychlejší trasa (více chodců a cílů)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Chodci vycházejí od budovy Fakulty stavební ČVUT v Praze (``osm_id:
2905257304``) a ze stanice Hradčanská (``osm_id: 1990839852``). Cílem
jsou nádraží Dejvice (``osm_id: 4196659626``) a tramvajová zastávka
Hradčanské náměstí (``osm_id: 2825726603``). Rychlost pohybu chodců
uvažujeme 1,2 m/s.

.. code-block:: sql

   SELECT osm_id, id FROM ways_vertices_pgr
   WHERE osm_id IN (2905257304, 4196659626, 1990839852, 2825726603);

::

      osm_id   |  id   
   ------------+-------
    2905257304 |  10824
    4196659626 | 141866
    1990839852 |  99683
    2825726603 | 109998

.. code-block:: sql
                
   SELECT * FROM pgr_dijkstra('
    SELECT gid AS id,
    source,
    target,
    length_m / 1.2 / 60 AS cost
    FROM ways',
   ARRAY[10824, 99683], ARRAY[141866, 109998], directed := false);

Časovou náročnost tras získáme následujícím příkazem (náklady v
minutách):

   .. code-block:: sql

      SELECT start_vid, end_vid, agg_cost FROM pgr_dijkstra('
       SELECT gid AS id,
       source,
       target,
       length_m / 1.2 / 60 AS cost
       FROM ways',
      ARRAY[10824, 99683], ARRAY[141866, 109998], directed := false)
      WHERE edge=-1 ORDER BY agg_cost;

   ::

       start_vid | end_vid |     agg_cost     
      -----------+---------+------------------
           99683 |  141866 | 4.92821083982696
           10824 |  141866 |  17.095297862879
           99683 |  109998 | 22.9298945807643
           10824 |  109998 | 35.6259236702052

.. tip:: Agregované náklady vrací přímo funkce `pgr_dijkstraCost
   <http://docs.pgrouting.org/latest/en/src/dijkstra/doc/pgr_dijkstraCost.html>`__,
   příklad:

   .. code-block:: sql

      SELECT * FROM pgr_dijkstraCost('
       SELECT gid AS id,
       source,
       target,
       length_m / 1.2 / 60 AS cost
       FROM ways',
      ARRAY[10824, 99683], ARRAY[141866, 109998], directed := false)
      ORDER BY agg_cost;

Příklad - automobil
^^^^^^^^^^^^^^^^^^^

Na rozdíl od chodce uvažujeme náklady ve směru (:dbcolumn:`cost`) a
proti směru (:dbcolumn:`reverse_cost`) hrany. V případě obousměrných
komunikací jsou oba náklady kladné, přičemž se ale mohou lišit. U
jednosměrných komunikací jeden z nákladů nabývá záporné hodnoty.

V našem případě se bude vozidlo pohybovat z Letiště Václava Havla
(Terminál 2, ``osm_id: 2088346069``) k historické budově Hlavní
nádraží (``osm_id: 2800419931``).


Nejkratší trasa
~~~~~~~~~~~~~~~

.. code-block:: sql

   SELECT a.*, b.geom AS geom FROM pgr_dijkstra('
    SELECT gid AS id,
    source,
    target,
    CASE WHEN cost > 0 THEN length_m ELSE -1 END AS cost,
    CASE WHEN reverse_cost > 0 THEN length_m ELSE -1 END AS reverse_cost
    FROM ways',
   (SELECT id FROM ways_vertices_pgr WHERE osm_id = 2088346069),
   (SELECT id FROM ways_vertices_pgr WHERE osm_id = 2800419931),
   directed := true) AS a
   LEFT JOIN ways AS b
   ON (a.edge = b.gid) ORDER BY seq;

Nejrychlejší trasa
~~~~~~~~~~~~~~~~~~

Před samotným výpočtem pro jednotlivé typy komunikací nastavíme
odpovídající maximální dovolené rychlosti. Na základě toho budou poté
určeny náklady pohybu v časových jednotkách. Náklady v atributu
:dbcolumn:`cost_s` jsou uvedeny v sekundách.

Příklad úpravy časových nákladu podle typu komunikace:

.. code-block:: sql

   ALTER TABLE osm_way_classes ADD COLUMN penalty FLOAT;
   UPDATE osm_way_classes SET penalty=100;
   UPDATE osm_way_classes SET penalty=0.8 WHERE name IN ('secondary', 'secondary_link',
                                                         'tertiary', 'tertiary_link');
   UPDATE osm_way_classes SET penalty=0.6 WHERE name IN ('primary','primary_link');
   UPDATE osm_way_classes SET penalty=0.4 WHERE name IN ('trunk','trunk_link');
   UPDATE osm_way_classes SET penalty=0.3 WHERE name IN ('motorway','motorway_junction','motorway_link');

.. code-block:: sql
                
   SELECT a.*, b.geom AS geom FROM pgr_dijkstra('
    SELECT gid AS id,
    source,
    target,
    cost_s * penalty AS cost,
    reverse_cost_s * penalty AS reverse_cost
    FROM ways JOIN osm_way_classes
    USING (class_id)',
   (SELECT id FROM ways_vertices_pgr WHERE osm_id = 2088346069),
   (SELECT id FROM ways_vertices_pgr WHERE osm_id = 2800419931),
   directed := true) AS a
   LEFT JOIN ways AS b
   ON (a.edge = b.gid) ORDER BY seq;

.. tip:: Po zavedení penalizace bude nejkratší trasa pro automobil
         věrohodnější:

   .. code-block:: sql
                   
      SELECT a.*, b.geom AS geom FROM pgr_dijkstra('
       SELECT gid AS id,
       source,
       target,
       CASE WHEN cost > 0 THEN length_m * penalty ELSE -1 END AS cost,
       CASE WHEN reverse_cost > 0 THEN length_m * penalty ELSE -1 END AS reverse_cost
       FROM ways JOIN osm_way_classes
       USING (class_id)',
      (SELECT id FROM ways_vertices_pgr WHERE osm_id = 2088346069),
      (SELECT id FROM ways_vertices_pgr WHERE osm_id = 2800419931),
      directed := true) AS a
      LEFT JOIN ways AS b
      ON (a.edge = b.gid) ORDER BY seq;

   .. todo:: upravit
      
.. figure:: ../images/route-auto.png

   Porovnání nejkratší (červeně) a nejrychlejší (modře) trasy z
   Letiště Václava Havla na Hlavní nádraží. Společná část trasy je
   znázorněna fialovou barvou.

Servisní síť
------------

Ćastou operací v síťových analýzách je výpočet servisní sítě.
Zajímá nás kam je možné se v rámci sítě dostat do určitého času. 
V tomto případě nastavíme 300 sekund.

Ještě trochu upravíme penalty pro průchod. Budeme uvažovat, že
můžeme jet kdekoli jen o něco málo pomaleji než po hlavních silnicích
a zásadně zvýhodníme jen dálnice.

.. code-block:: sql

   UPDATE osm_way_classes SET penalty=1.2;
   UPDATE osm_way_classes SET penalty=1.0 WHERE name IN ('secondary', 'secondary_link',
                                                         'tertiary', 'tertiary_link');
   UPDATE osm_way_classes SET penalty=1.0 WHERE name IN ('primary','primary_link');
   UPDATE osm_way_classes SET penalty=1.0 WHERE name IN ('trunk','trunk_link');
   UPDATE osm_way_classes SET penalty=0.8 WHERE name IN ('motorway','motorway_junction','motorway_link'); 

.. code-block:: sql
                
   SELECT a.*, b.geom AS geom FROM pgr_drivingDistance('
    SELECT gid AS id,
    source,
    target,
    cost_s * penalty AS cost,
    reverse_cost_s * penalty AS reverse_cost
    FROM ways JOIN osm_way_classes
    USING (class_id)',
   (SELECT id FROM ways_vertices_pgr WHERE osm_id = 250862),
   300,
   directed := true) AS a
   LEFT JOIN ways AS b
   ON (a.edge = b.gid) ORDER BY seq;

      
.. figure:: ../images/route-distance.png

   Servisní síť z vybraného místa.

Algoritmus má limity, které jsme zatím podrobně netestovali,
přesto pro určení přibližného servisního území (sítě) může posloužit.

Cesta obchodního cestujícího
----------------------------

Vyjíždíme z Dejvic (id: 12333). Chceme se cestou zastavit na výstavišti v Holešovicích (id: 7436),
v Europarku (id: 144884) a na Andělu (id: 116748) a pak dojet zpátky do Dejvic. Algoritimus naplánuje 
cestu tak, abychom navštívili každé místo pouze jednou a urazili cestu
s nejmenšími náklady. 

Využití vzdálenosti po síti
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Navržená cesta je přes Anděla, Europark, Holešovice.

.. code-block:: sql

   SELECT * FROM pgr_TSP(
       $$
       SELECT * FROM pgr_dijkstraCostMatrix(
           'SELECT gid as id, source, target, cost, reverse_cost FROM ways',
           (SELECT array_agg(id) FROM ways_vertices_pgr WHERE id IN (12333, 7436, 144884, 116748)),
           directed := false
       )
       $$,
       start_id := 12333,
       randomize := false
   );


::

    seq |  node  |        cost        |      agg_cost      
   -----+--------+--------------------+--------------------
      1 |  12333 | 0.0484455749225172 |                  0
      2 | 116748 |  0.148717683986367 | 0.0484455749225172
      3 | 144884 |  0.133988564693275 |  0.197163258908885
      4 |   7436 | 0.0443240851172554 |   0.33115182360216
      5 |  12333 |                  0 |  0.375475908719415


Využití euklidovské vzdálenosti
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

K dispozici je také výpočet cesty obchodního cestujícího, která
využívá pouze euklidovský prostor. Tento výpočet je sice méně přesný,
ale měl by být o dost rychlejší, zejména v případě většího počtu míst.
Rychlost jsme netestovali.

Navržená cesta je přes Anděla, Holešovice a Europark. Tedy jinak než
v případě předchozího algoritmu.

.. code-block:: sql

   SELECT * FROM pgr_eucledianTSP('SELECT *
   FROM (
     SELECT DISTINCT id AS source_id,
                       ST_X(geom) AS x,
                       ST_Y(geom) AS y FROM ways_vertices_pgr
             WHERE id IN (12333, 7436, 144884, 116748)
   ) t
   ORDER BY
   CASE source_id
     WHEN 12333 THEN 1 
     WHEN 7436 THEN 2
     WHEN 144884 THEN 3
     WHEN 116748 THEN 4  
    END');


::

     seq | node |         cost          |      agg_cost      
    -----+------+-----------------------+--------------------
       1 |    1 |    0.0382006302085469 |                  0
       2 |    4 |    0.0462512161967639 | 0.0382006302085469
       3 |    2 |     0.117270931512459 | 0.0844518464053108
       4 |    3 | 4.64686056594346e-310 |   0.20172277791777
       5 |    1 |                     0 |   0.20172277791777


   
Další materiály
---------------

* http://workshop.pgrouting.org
