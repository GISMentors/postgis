Rastrová data
=============

.. todo:: nedokonceno

Podporu pro práci s rastrovými daty poskytuje PostGIS až od verze 2.0
a to v rámci rozšíření `PostGIS Raster
<http://postgis.net/docs/using_raster_dataman.html>`_.

.. note:: PostGIS Raster je součástí rozšíření ``postgis``, není
          potřeba ho zvlášt přidávat.

Rastrová data mohou být spravována ve dvou formách jako:

#. **IN-DB**, tj. uložena přímo v databázi anebo
#. **OUT-OF-DB**, tj. mimo databázi.

Nahraní rastrových dat do databáze
----------------------------------

Podobně jako u :doc:`vektorových dat <3_shp2pgsql_a_davkove_nahrani>`
lze data nahrát pomocí specializovaného nástroje, který je součástí
PostGISu :program:`raster2pgsql`.

.. important:: Knihovna GDAL formát PostGIS Raster podporuje nicméně v
               současnosti neumožnuje konverzi dat z jiných formátu to
               PostGIS Raster.

Nejprve si stáhneme testovací data `DMT
<http://training.gismentors.eu/geodata/eu-dem/dmt.zip>`_ (digitální
model terénu) a soubor dekomprimujeme ``unzip dmt.zip``.

.. _import-raster2pgsql:

raster2pgsql
^^^^^^^^^^^^

Příkaz `raster2pgsql
<http://postgis.net/docs/using_raster_dataman.html#RT_Raster_Loader>`_
funguje obdobně jako :ref:`import-shp2pgsql` pro vektorová data ve
formátu Esri Shapefile. Pomocí tohoto nástroje lze rastrová data do
PostGISu jak v režimu **IN-DB** i **OUT-OF-DB**.

Režim IN-DB
~~~~~~~~~~~

.. notecmd:: Načtení rastrových dat pomocí raster2pgsql (IN-DB)

   .. code-block:: bash

      raster2pgsql -s 3035 dmt.tif ukol_1.dmt | psql pokusnik 2>err

.. note:: Tento přikaz nicméně může skončit chybou typu

   ::
    
      ERROR:  invalid memory alloc request size 1073741824

   která naznačuje, že máme nedostatek paměti pro import tohoto rastru.

   Tento problém můžeme např. obejít parametrem :option:`-Y`, který
   pošle do PGDump příkaz :sqlcmd:`COPY` namísto :sqlcmd:`INSERT`.

   Přidáme ještě užitečný přepínač :option:`-C`, který nastaví omezení
   na importovana data. Jinak by například byl ignorován souřadnicový
   systém a pod.

   .. code-block:: bash

      raster2pgsql -s 3035 -Y -C dmt.tif ukol_1.dmt | psql pokusnik 2>err

     

Režim IN-DB
~~~~~~~~~~~

V tomto režimu nedochází k importu vstupních dat do PostGISu, ale
pouze k vytvoření odkazu z databáze na původní data. Rastrová data
jsou tedy fyzicky uložena *mimo* databázi.

.. notecmd:: Načtení rastrových dat pomocí raster2pgsql (OUT-OF-DB)

   .. code-block:: bash

      raster2pgsql -s 3035 -R -C `pwd`/dmt.tif ukol_1.dmt_link | psql pokusnik 2>err

   Cesta k soubor musí být uplná, jinak nebude link korektní. My jsme
   si pomohly unixovým příkazem :program:`pwd`, který vrátí cestu k
   aktuálnímu adresáři, ve kterém jsou umístěna importovaná data.

Základní metadata
-----------------

V sekci :ref:`import-raster2pgsql` jsme naimportovali rastr DMT ve
dvou formách jako **IN-DB** (tabulka :dbtable:`ukol_1.dmt`) a
**OUT-OF-DB** (tabulka :dbtable:`ukol_1.dmt_link`).

.. code-block:: sql

   SELECT r_table_schema,r_table_name,srid,out_db FROM raster_columns;

::
   
   r_table_schema | r_table_name | srid | out_db 
  ----------------+--------------+------+--------
   ukol_1         | dmt          | 3035 | {f}
   ukol_1         | dmt_link     | 3035 | {t}

Tabulka :dbtable:`raster_columns` ukrývá další užitečné informace.

.. code-block:: sql
		
   SELECT scale_x,scale_y,blocksize_x,blocksize_y,same_alignment,
    regular_blocking,num_bands,pixel_types,nodata_values,ST_AsText(extent) as extent
    FROM raster_columns where r_table_name = 'dmt';

::

   scale_x          | 25
   scale_y          | -25
   blocksize_x      | 19615
   blocksize_y      | 11119
   same_alignment   | t
   regular_blocking | f
   num_bands        | 1
   pixel_types      | {16BUI}
   nodata_values    | {65535}
   extent           | POLYGON((4470075 3113850,4960450 3113850,4960450 2835875,4470075 2835875,4470075 3113850))

.. note:: Záporná hodnota ``scale_y`` naznačuje orientaci rastru ze
          severu na jih.

Kde je:

.. table::
   :class: noborder

   +----------------------+-------------------------------------------------------+
   | ``scale_x``          | prostorové rozlišení ve směru osy x                   |
   +----------------------+-------------------------------------------------------+
   | ``scale_y``          | prostorové rozlišení ve směru osy y                   |
   +----------------------+-------------------------------------------------------+
   | ``blocksize_x``      | velikost dlaždice ve směru osy x                      |
   +----------------------+-------------------------------------------------------+
   | ``blocksize_y``      | velikost dlaždice ve směru osy y                      |
   +----------------------+-------------------------------------------------------+
   | ``same_alignment``   | mají všechny dlaždice stejné zarovnání                |
   +----------------------+-------------------------------------------------------+
   | ``regular_blocking`` | mají všchny dlaždice stejný rozměr a nepřekrývají se  |
   +----------------------+-------------------------------------------------------+
   | ``num_bands``        | počet kanálů                                          |
   +----------------------+-------------------------------------------------------+
   | ``pixel_types``      | datový typ buněk kanálů                               |
   +----------------------+-------------------------------------------------------+
   | ``nodata_values``    | hodnota pro no-data jednotlivých kanálů               |
   +----------------------+-------------------------------------------------------+
   | ``extent``           | minimální ohraničující obdélník datové vrstvy         |
   +----------------------+-------------------------------------------------------+

.. note:: Porovnáme-li velikost dlaždice (``blocksize_x`` a
	  ``blocksize_y``) a velikost vstupního rastru (například
	  pomocí nástroje knihovny GDAL :program:`gdalinfo`, tak
	  dojdeme, že se rastr naimportoval jako jedna dlaždice.

	  .. code-block:: bash

	     gdalinfo dmt.tif -noct

	  Pro rozdělení rastrových dat při importu do více dlaždic
	  slouží parametr :option:`-t` (``<šířka>x<výška>``) programu
	  :program:`raster2pgsql`.

	  .. notecmd:: Rozdělení dat do více dlaždic při importu
		       
	     Velikost dlaždice zvolíme ``400x400px``.
	     
	     .. code-block:: bash

		raster2pgsql -s 3035 -Y -C -t 400x400 dmt.tif ukol_1.dmt_tiled | psql pokusnik 2>err

	     Rastr se v tomto případě naimportuje jako 1400 dlaždic.
	     
	     .. code-block:: sql

		SELECT COUNT(*) FROM ukol_1.dmt_tiled;
	     

Příklad
-------

*Vejce vesmírných oblud v nadmořské výšce na XXX metrů jsou
oslabena. Využijte toho a zlikvidujte je.*

Zadání
^^^^^^

Určete nadmořskou výšku bodů s výskytem vajec na základě rastru DMT. Vyberte body s nadmořskou výškou větší než 300 metrů.

Řešení
^^^^^^

Geometrie tabulky :dbtable:`vesmirne_zrudnice` je v systému S-JTSK
(:epsg:`5514`), rastrová data v ETRS-89 (:epsg:`3035`). V rámci řešení
tedy musíme počítat s transformaci dat do společného souřadnicového
systému pomocí funkce :pgiscmd:`ST_Transform`.

.. code-block:: sql

   -- nastavevíme cestu
   SET search_path TO ukol_1, public;

   SELECT v.id,ST_Value(r.rast,v.geom) FROM dmt AS r CROSS JOIN
    (SELECT id,ST_Transform(geom_p, 3035) AS geom FROM vesmirne_zrudice) AS v;

   -- optimalizovaná verze dotazu (dmt -> dmt_tiled)
   SELECT v.id,ST_Value(r.rast,v.geom) FROM dmt_tiled AS r JOIN
    (SELECT id,ST_Transform(geom_p, 3035) AS geom FROM vesmirne_zrudice) AS v ON
    ST_Intersects(r.rast,v.geom);

Výsledek uložíme do nového sloupečku v tabulce
:dbtable:`vesmirne_zrudnice` a vybereme body s nadmořskou výškou větší než 300 metrů.

.. code-block:: sql

   ALTER TABLE vesmirne_zrudice ADD COLUMN vyska FLOAT;

   UPDATE vesmirne_zrudice SET vyska = value FROM
   (             
    SELECT v.id AS vid,ST_Value(r.rast,v.geom) AS value FROM dmt_tiled AS r JOIN
     (SELECT id,ST_Transform(geom_p, 3035) AS geom FROM vesmirne_zrudice) AS v ON
     ST_Intersects(r.rast,v.geom)
   ) AS v WHERE id = vid;

   SELECT id FROM vesmirne_zrudice WHERE vyska > 300;
    
Užitečné odkazy
---------------

* http://freegis.fsv.cvut.cz/gwiki/PostGIS_Raster
* `Funkce rozšíření PostGIS Topology <http://postgis.net/docs/RT_reference.html>`_
