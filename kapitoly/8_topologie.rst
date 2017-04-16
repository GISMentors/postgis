Topologie
=========

*PostGIS vznikl jako projekt implementující standard OGC* `Simple
Features <http://www.opengeospatial.org/standards/sfa>`_ *pro práci s
vektorovými daty ve formě jednoduchých prvků. Od verze 2.0 nicméně
umožnuje práci s vektorovými daty také v topologické formě.*

Rozšíření pro topologická vektorová data nahrajeme příkazem:

.. code-block:: sql
   
  CREATE EXTENSION postgis_topology;

Topologický datový model
------------------------

Rozdíl mezi datovým modelem jednoduchých geoprvků (simple features) a
topologickým modelem si ukážeme na případě dvou sousedících polygonů.

Jednoduché prvky
^^^^^^^^^^^^^^^^

.. _priklad-polygony-sf:

.. figure:: ../images/postgis-polygon-example.png
   :class: small

   Dva sousedící polygony jako jednoduché geoprvky.

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
* hranami (*edges*) 
* stěnami (*faces*) 

Kompozice znázorněná na :ref:`obrázku výše <priklad-polygony-sf>` bude
v topologickém modelu PostGISu popsána:

* dvěma uzly :fignote:`N1` a :fignote:`N2`
* třemi hranami :fignote:`E1`, :fignote:`E2` a :fignote:`E3`
* dvěma stěnami :fignote:`F1` a :fignote:`F2`

.. figure:: ../images/postgis-topo-polygon-example.png
   :class: small

   Dva sousedící polygony z :num:`#priklad-polygony-sf` v topologickém
   modelu.

Ve výsledku bude tedy společná hranice polygonů :fignote:`A` a
:fignote:`B` uložena pouze jednou a to jako hrana :fignote:`E1`.

.. tip:: Podrobné informace k tomuto tématu `zde
         <http://geo.fsv.cvut.cz/~gin/uzpd/uzpd.pdf#146>`_.

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

Tabulky s topologickými primitivy
---------------------------------

Topologická primitiva jsou uloženy v tabulkách topologického schématu :dbtable:`node`, :dbtable:`edge` a :dbtable:`face`.

.. code-block:: sql

   -- seznam uzlů
   SELECT node_id,containing_face,st_astext(geom) from topo_p2.node;

   -- seznam hran
   SELECT edge_id,start_node,end_node,next_left_edge,next_right_edge,
    left_face,right_face,st_astext(geom) from topo_p2.edge;         

   -- seznam stěn
   SELECT face_id,ST_AsText(mbr) from topo_p2.face;        

Kontrola konzistence dat
------------------------

Pro kontrolu topologické konzistence můžete použít dvě funkce
:pgiscmd:`TopologySummary` a :pgiscmd:`ValidateTopology`. První z nich
vypisuje souhrné informace o topologii, druhá provádí validaci
topologických primitiv.

.. code-block:: sql

   SELECT TopologySummary('topo_p2');
   SELECT ValidateTopology('topo_p2');

Praktická ukázka
----------------

Z důvodu časové náročnosti si topologii sestavíme pouze na vzorku
parcel na uzemí Hlavního města Prahy.

.. code-block:: sql

   -- vybereme část parcel na území Hl. města Prahy
   CREATE TABLE parcely_732583 AS
    SELECT * FROM ruian_praha.parcely WHERE katastralniuzemikod = 732583;

   -- přídáme primární klíč
    ALTER TABLE parcely_732583 ADD PRIMARY KEY (ogc_fid);            

   -- a prostorové indexy
   CREATE INDEX ON parcely_732583 USING gist (geom);
                
Vytvoříme nové schéma a atribut pro topologii.

.. code-block:: sql
   
   -- topologické schéma
   SELECT CreateTopology('topo_parcely_732583', 5514);

   -- topologický atribut
   SELECT AddTopoGeometryColumn('topo_parcely_732583', 'topo_test',
    'parcely_732583', 'topo', 'POLYGON');

.. tip:: Souřadnicový systém pro topologické schéma můžeme odvodit
         dynamicky pomocí funkce ``find_srid``,
         např. ``find_srid('topo_test', 'parcely_732583', 'geom')``.

Nakonec se pokusíme topologii sestavit z naimportovaných jednoduchých
prvků.

.. code-block:: sql

   UPDATE parcely_732583 SET topo = toTopoGeom(geom, 'topo_parcely_732583', 1);

.. note:: Sestavení topologie z jednoduchých geoprvků je poměrně
          časově náročná činnost. Na výše uvedeném katastrálním území
          může trvat až několik minut. Funkce :pgiscmd:`toTopoGeom` je
          navíc velmi náchylná na topologické chyby na vstupu a často
          skončí chybou.

.. noteadvanced:: Pro sestavení topologie můžete použít jako externí
   nástroj `GRASS GIS
   <http://www.gismentors.cz/skoleni/grass-gis/>`_. Následuje zkracený
   návod. Detaily tohoto řešení jsou nad rámec tohoto školení a
   spadají spíše do školení :skoleni:`GRASS GIS pro pokročilé
   <grass-gis-pokrocily>`.

   .. code-block:: bash

      v.in.ogr in=PG:dbname=pokusnik layer=ukol_1.parcely out=parcely
      v.out.postgis -l in=parcely out=PG:dbname=pokusnik out_layer=parcely_topo
                             
Zadání
^^^^^^

Najděte parcely, které sousedí s parcelou, ve které se nachází adresní
bod s označením ``kod=22560840``.

Řešení
^^^^^^

.. code-block:: sql

   SELECT (ST_GetFaceEdges('topo_parcely_732583', f.face_id)).edge FROM
   (             
    SELECT face_id FROM topo_parcely_732583.face AS f JOIN
     ruian_praha.adresnimista AS a ON a.kod=22560840 AND a.geom && f.mbr AND
     ST_Within(a.geom, ST_GetFaceGeometry('topo_parcely_732583', f.face_id))
   ) AS f;

   
   SELECT id, kmenovecislo || '/' || pododdelenicisla AS parcela
    FROM parcely_732583
    WHERE (topo).id IN
    (
     SELECT CASE WHEN ee.edge < 0 THEN left_face ELSE right_face END
      FROM topo_parcely_732583.edge AS e JOIN
      (
	SELECT (ST_GetFaceEdges('topo_parcely_732583', f.face_id)).edge FROM
	(
	   SELECT face_id FROM topo_parcely_732583.face AS f JOIN
           ruian_praha.adresnimista AS a ON a.kod=22560840 AND a.geom && f.mbr AND
           ST_Within(a.geom, ST_GetFaceGeometry('topo_parcely_732583', f.face_id))
         ) AS f
      ) AS ee
     ON abs(ee.edge) = e.edge_id
    );

.. code-block:: sql

   WITH original_face_id AS(
      SELECT
      topology.getFaceByPoint('topo_parcely_732583', geom, 0) face_id
      FROM ruian_praha.adresnimista WHERE kod = 22560840
   )
   , sousedni AS (
      SELECT
      CASE right_face
         WHEN original_face_id.face_id THEN left_face
         ELSE right_face
      END face
      FROM original_face_id
      , topology.ST_GetFaceEdges('topo_parcely_732583', face_id)
      JOIN topo_parcely_732583.edge ON edge_id = @edge
   )
   SELECT *
   FROM topo_test.parcely_732583 p
   JOIN topo_parcely_732583.relation r
   ON (p.topo).id = r.topogeo_id
   AND (p.topo).layer_id = r.layer_id
   AND (p.topo).type = 3
   WHERE r.element_id IN (
      SELECT face
      FROM sousedni
   );
                
Užitečné odkazy
---------------

* `Funkce rozšíření Topology <http://postgis.net/docs/Topology.html>`_
* http://freegis.fsv.cvut.cz/gwiki/PostGIS_Topology
* http://grasswiki.osgeo.org/wiki/PostGIS_Topology
