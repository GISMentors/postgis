Úvod
====

.. image:: images/postgis-logo.png
	   :width: 140px
	   :align: left

**PostGIS** je rozšíření objektově-relačního databázového systému
:wikipedia:`PostgreSQL` pro podporu geografických objektů. PostGIS
implementuje specifikaci `Simple Features
<http://www.opengeospatial.org/standards/sfa>`_ konsorcia
:wikipedia:`Open Geospatial Consortium`.

Kromě podpory práce s vektorovými daty v podobě jednoduchých geoprvků
(simple features) podporuje PostGIS 2.0 i vektorová data v
topologickém formátu a bezešvý přístup k uložení rastrových dat a
jejich využití v prostorovém SQL v souvislosti s daty vektorovými.

PostGIS je multiplatformní a plně funkční na platformách jako
GNU/Linux, MS Windows či Mac OSX.

Vstupní znalost
---------------

* Uživatel zná základy :wikipedia:`SQL`

Výstupní dovednost
------------------

* Uživatel zvládne naimportovat data do PostGIS a to i dávkově
* Uživatel zvládne exportovat data z PostGIS do jiných GIS formátů
* Uživatel je schopen data vizualizovat
* Uživatel má povědomí s čím rámcově musí počítat, když chce pracovat
  s většími objemy data (dejme tomu RÚIAN pro Prahu na slabším stroji)
* Uživatel je schopen provádět prostorové dotazy
* Uživatel zvládá samostatně řešit jednoduché analýzy v PostGIS

Požadavky
---------

* PC s OS GNU/Linux (např. `OSGeoLive <http://live.osgeo.org>`_),
  `PostgreSQL <http://www.postgresql.org>`_, `QGIS
  <http://www.qgis.org>`_ a připojení k internetu, volitelně
  `pgAdminIII <http://www.pgadmin.org/>`_, `LibreOffice
  <http://www.libreoffice.org/>`_
* Alternativně přístup na server přes :program:`ssh`, na kterém běží
  PostgreSQL, na klientovi :program:`psql`. Data stačí prohlížet přes
  webový prohlížeč (webový QGIS)
* `PostGIS 2.0 <http://www.postgis.net>`_ a vyšší
* `pracovní data <http://training.gismentors.eu/geodata/postgis/>`_

Obsah
=====

.. warning:: Toto je pracovní verze školení, která je aktuálně ve vývoji!

.. toctree::
   :maxdepth: 3

   kapitoly/0_uvod
   kapitoly/1_vytvarime_prostorovou_db
   kapitoly/2_tvorba_jednoduche_prostorove_tabulky
   kapitoly/3_shp2pgsql_a_davkove_nahrani
   kapitoly/4_prostorove_operatory
   kapitoly/5_prostorove_funkce
   kapitoly/6_obludy
   kapitoly/7_topologie
   kapitoly/8_rastry
   kapitoly/9_zaver

O dokumentu
-----------

Text dokumentu je licencován pod `Creative Commons
Attribution-ShareAlike 4.0 International License
<http://creativecommons.org/licenses/by-sa/4.0/>`_.

.. figure:: images/cc-by-sa.png 
	    :width: 130px
	    :scale-latex: 120
              
*Verze textu dokumentu:* |release| (sestaveno |today|)

Autoři
^^^^^^

Za `GISMentors <http://www.gismentors.cz/>`_:

* Jan Michálek ``<godzilalalala gmail.com>``

Text dokumentu
^^^^^^^^^^^^^^

.. only:: latex

   Online HTML verze textu školení je dostupná na adrese:

   * http://training.gismentors.eu/postgis

Zdrojové texty školení jsou dostupné na adrese:

* https://github.com/GISMentors/postgis
