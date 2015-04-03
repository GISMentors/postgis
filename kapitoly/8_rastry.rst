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

      raster2pgsql -s 5514 dmt.tif ukol_1.dmt | psql pokusnik 2>err

.. note:: Tento přikaz nicméně může skončit chybou typu

   ::
    
      ERROR:  invalid memory alloc request size 1073741824

   která naznačuje, že máme nedostatek paměti pro import tohoto rastru.

   Tento problém můžeme např. obejít parametrem :option:`-Y`, který
   pošle do PGDump příkaz :sqlcmd:`COPY` namísto :sqlcmd:`INSERT`.

   .. code-block:: bash

      raster2pgsql -s 5514 -Y dmt.tif ukol_1.dmt | psql pokusnik 2>err

Režim IN-DB
~~~~~~~~~~~

V tomto režimu nedochází k importu vstupních dat do PostGISu, ale
pouze k vytvoření odkazu z databáze na původní data. Rastrová data
jsou tedy fyzicky uložena *mimo* databázi.

.. notecmd:: Načtení rastrových dat pomocí raster2pgsql (OUT-OF-DB)

   .. code-block:: bash

      raster2pgsql -s 5514 -R `pwd`/dmt.tif ukol_1.dmt_link | psql pokusnik 2>err

Základní metadata
-----------------

V sekci :ref:`import-raster2pgsql` jsme naimportovali rastr DMT ve
dvou formách jako **IN-DB** (tabulka :dbtable:`ukol_1.dmt`) a
**OUT-OF-DB** (tabulka :dbtable:`ukol_1.dmt_link`).

.. code-block:: sql

   SELECT r_table_schema,r_table_name,out_db FROM raster_columns;
