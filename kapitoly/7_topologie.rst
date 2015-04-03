Topologie
=========

.. todo:: nedokonceno

*PostGIS vznikl jako projekt implementující standard OGC* `Simple
Features <http://www.opengeospatial.org/standards/sfa>`_ *pro práci s
vektorovými daty ve formě jednoduchých prvků. Od verze 2.0 nicméně
umožnuje práci s vektorovými daty také v topologické formě.*

.. warning:: Podporováno od verze PostGIS 2.0 a vyšší

Rozšíření pro topologická vektorová data nahrajeme příkazem:

.. code-block:: sql
   
   CREATE EXTENSION postgis_topology;

Topologický datový model
------------------------

Podrobné informace k tomuto tématu `zde
<http://geo.fsv.cvut.cz/~gin/uzpd/uzpd.pdf#146>`_.

Rozdíl mezi datovým modelem jednoduchých geoprvků (simple features) a
topologickým modelem si ukážeme na případě dvou sousedících polygonů.

Jednoduché prvky
^^^^^^^^^^^^^^^^

.. _priklad-polygony-sf:

.. figure:: ../images/postgis-polygon-example.png
   :class: small

   Dva sousedící polygony v modelu simple features

::

  polygon |              geometrie (WKT)                   
 ---------+----------------------------------------------
     A    | POLYGON((100 0,0 0,0 100,100 100,100 0))
     B    | POLYGON((100 0,100 100,200 100,200 0,100 0))

Z výše uvedeného je evidentní, že jsou oba prvky uloženy odděleně. To
vede k tomu, že hranice sousedících polygonů je uložena
dvakrát. Jednou jako součást polygonu :fignote:`A` podruhé jako součást
polygonu :fignote:`B`.

Topologický datový model
^^^^^^^^^^^^^^^^^^^^^^^^

PostGIS Topology používá datový model Topo-Geo, který vychází z
technické normy SQL/MM (`ISO 13249-3:2006
<http://www.wiscorp.com/H2-2004-168r2-Topo-Geo-and-Topo-Net-1-The-Concepts.pdf>`_).

Model pracuje s třemi základními *topologickými primitivy*:

* uzly (*nodes*) 
* hrany (*edges*) 
* stěny (*faces*) 

Kompozice znázorněná na :ref:`obrázku výše <priklad-polygony-sf>` bude
v topologickém modelu PostGISu popsána:

* dvěma uzly :fignote:`N1` a :fignote:`N2`
* třemi hranami :fignote:`E1`, :fignote:`E2` a :fignote:`E3`
* dvěma stěnami :fignote:`F1` a :fignote:`F2`

.. figure:: ../images/postgis-topo-polygon-example.png
   :class: small

   Dva sousedící polygony v topologickém modelu

Ve výsledku bude tedy společná hranice polygonů :fignote:`A` a
:fignote:`B` uložena pouze jednou a to jako hrana :fignote:`E1`.

Příklad
^^^^^^^

.. code-block:: sql

   -- vytvoříme pracovní schéma a nastavíme vyhledávací cestu
   CREATE schema topo_test;
   -- schéma topology a public musí být v cestě uvedeno vždy
   SET search_path TO topo_test,topology,public;

   -- nahrání dat ve formě simple features
   CREATE TABLE p2 (fid serial PRIMARY KEY, geom geometry(Polygon));
   INSERT INTO p2 (geom) VALUES (ST_GeomFromText('Polygon(
    (0 0, 100 0, 100 100, 0 100, 0 0))'));
   INSERT INTO p2 (geom) VALUES (ST_GeomFromText('Polygon(
    (100 0, 200 0, 200 100, 100 100, 100 0))'));
    
Každá datová vrstva s topologii je uložena ve zvláštním schématu, nové
schéma vytvoříme pomocí funkce :pgiscmd:`CreateTopology`.

.. code-block:: sql

   SELECT CreateTopology('topo_p2');

.. tip:: Topologická schéma jsou uložena v tabulce :dbtable:`topology`
         (schéma :dbtable:`topology`).

Do tohoto schématu vložíme nový atribut, do kterého posléze sestavíme
topologii prvků. K tomu použijeme funkce :pgiscmd:`AddTopoGeometryColumn`.

.. code-block:: sql

   SELECT AddTopoGeometryColumn('topo_p2', 'topo_test', 'p2', 'topo', 'POLYGON');

Ve výsledku se v tabulce :dbtable:`p2` vytvoří nový sloupce s názvem
:dbcolumn:`topo` a datovým typem :ref:`TopoGeometry <topogeometry>`.

.. tip:: Atributy s topologií jsou uloženy v tabulce :dbtable:`layer`
         (schéma :dbtable:`topology`).

Topologická primitiva sestavíme z jednoduchým prvků pomocí funkce
:pgiscmd:`toTopoGeom`.

.. code-block:: sql

   UPDATE p2 SET topo = toTopoGeom(geom, 'topo_p2', 1);

.. note:: Poslední argument určuje toleranci se kterou budeme
          topologii sestavovat. Zde jsme zvolili toleranci 1~metr.

.. _topogeometry:

Datový typ TopoGeometry
-----------------------

Datový typ **TopoGeometry** reprezentuje geometrii definovanou
topologickými primitivy. Je složen ze čtyř složek:

* ``topology_id`` (id topologického schématu v tabulce :dbtable:`topology`)
* ``layer_id`` (id topologického atributu v tabulce :dbtable:`layer`)
* ``id`` (id topologického primitiva)
* ``type`` (geometrický typ jednoduchého prvku)
 * ``1`` bod (point)
 * ``2`` lomená čára (linestring)
 * ``3`` polygon

.. code-block:: sql

   SELECT fid,ST_AsText(geom),topo FROM p2;

V našem případě:

::

    fid |                  st_astext                   |   topo    
   -----+----------------------------------------------+-----------
      1 | POLYGON((0 0,100 0,100 100,0 100,0 0))       | (1,1,1,3)
      2 | POLYGON((100 0,200 0,200 100,100 100,100 0)) | (1,1,2,3)

Kontrola data
-------------

Pro kontrolu topologické konzistence můžete použít dvě funkce
:pgiscmd:`TopologySummary` a :pgiscmd:`ValidateTopology`. První z nich
vypisuje souhrné informace o topologii, druhá provádí validaci
topologických primitiv.

.. code-block:: sql

   SELECT TopologySummary('topo_p2');
   SELECT ValidateTopology('topo_p2');

Praktická ukázka
----------------

Pokusíme se sestavit topologii pro parcely na uzemí Hlavního města
Prahy. Nejprve si stáhneme `data
<http://training.gismentors.eu/geodata/postgis/parcely.dump>`_ a
naimportujeme do PostGISu.

.. notecmd:: Import datové vrstvy parcel

   .. code-block:: bash

      pg_restore -d pokusnik parcely.dump

Vytvoříme nové schéma a atribut pro topologii.

.. code-block:: sql

   -- nejprve nastavíme vyhledávací cestu
   SET search_path TO ukol_1, topology, public;
   
   -- topologické schéma
   SELECT CreateTopology('topo_parcely', 5514);

   -- topologický atribut
   SELECT AddTopoGeometryColumn('topo_parcely', 'ukol_1', 'parcely', 'topo', 'POLYGON');

.. tip:: Souřadnicový systém pro topologické schéma můžeme odvodit
         dynamicky pomocí funkce ``find_srid``,
         např. ``find_srid('ukol_1', 'parcely', 'originalnihranice')``.

Nakonec se pokusíme topologii sestavit z naimportovaných jednoduchých
prvků.

.. code-block:: sql

   UPDATE parcely SET topo = toTopoGeom(originalnihranice, 'topo_parcely', 1);

.. note:: Sestavení topologie z jednoduchých geoprvků je poměrně
          časově náročná činnost. Funkce :pgiscmd:`toTopoGeom` není z
          nejrychlejších (na testovacím stroji trvalo sestavení
          topologie parcel **více než 17 hod!!!**). Navíc je velmi náchylná
          na topologické chyby na vstupu a často skončí chybou.

.. noteadvanced:: Pro sestavení topologii můžete použít jako externí
                  nástroj `GRASS GIS
                  <http://www.gismentors.cz/skoleni/grass-gis/>`_. Následuje
                  zkracený návod. Detaily tohoto řešení jsou nad rámec
                  tohoto kurz a spadají spíše do kurzu `GRASS GIS pro
                  pokročilé
                  <http://www.gismentors.cz/skoleni/grass-gis/#pokrocily>`_.

		  .. todo::
		     
		  .. code-block:: bash

		     ...

Užitečné odkazy
---------------

* http://freegis.fsv.cvut.cz/gwiki/PostGIS_Topology
* http://grasswiki.osgeo.org/wiki/PostGIS_Topology
