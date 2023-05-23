.. only:: latex

   #####
   Obsah
   #####

.. only:: html

   `GISMentors <http://gismentors.cz>`_ | Školení `GRASS GIS
   <http://gismentors.cz/skoleni/grass-gis>`_ | `QGIS
   <http://gismentors.cz/skoleni/qgis>`_ | `PostGIS
   <http://gismentors.cz/skoleni/postgis>`_ | `GeoPython
   <http://gismentors.cz/skoleni/geopython>`_
   
   ****
   Úvod
   ****

.. only:: html
          
   .. image:: images/postgis-logo.png
              :width: 140px
              :align: left
                 
**PostGIS** je rozšíření objektově-relačního databázového systému
:wikipedia:`PostgreSQL` pro podporu geografických objektů. PostGIS
implementuje specifikaci `Simple Features
<http://www.opengeospatial.org/standards/sfa>`_ konsorcia
:wikipedia:`Open Geospatial Consortium`.

.. only:: latex

   .. figure:: images/postgis-logo.png
      :scale-latex: 40

      Logo projektu PostGIS

Kromě podpory práce s vektorovými daty v podobě jednoduchých geoprvků
(simple features) podporuje PostGIS 3.0 i vektorová data v
topologickém formátu a bezešvý přístup k uložení rastrových dat a
jejich využití v prostorovém SQL v souvislosti s daty vektorovými.

PostGIS je multiplatformní a plně funkční na platformách jako
GNU/Linux, MS Windows či Mac OSX.

.. index::
   pair: datové sady; ke stažení

.. notedata::

   Datová sada je stažitelná pro PostgreSQL ve `formátu dump
   <http://training.gismentors.eu/geodata/postgis/gismentors.dump>`_
   (595 MB). Blížší informace o importu ve :skoleni:`školení pro
   začátečníky <postgis-zacatecnik/kapitoly/7_instalace.html>`, na které
   toto školení do jisté míry navazuje.

.. warning:: :red:`Toto je pracovní verze školení, která je aktuálně
             ve vývoji!`

**Vstupní znalost**

* Uživatel zná základy :wikipedia:`SQL`

**Výstupní dovednost**

* Uživatel zvládne naimportovat data do PostGIS a to i dávkově
* Uživatel zvládne exportovat data z PostGIS do jiných GIS formátů
* Uživatel je schopen data vizualizovat
* Uživatel má povědomí s čím rámcově musí počítat, když chce pracovat
  s většími objemy data (dejme tomu RÚIAN pro Prahu na slabším stroji)
* Uživatel je schopen provádět prostorové dotazy
* Uživatel zvládá samostatně řešit jednoduché analýzy v PostGIS

**Požadavky**

* PC s OS GNU/Linux (např. `OSGeoLive <http://live.osgeo.org>`_),
  `PostgreSQL <http://www.postgresql.org>`_ a připojení k internetu,
  volitelně `pgAdmin <http://www.pgadmin.org/>`_, `LibreOffice
  <http://www.libreoffice.org/>`_
* Alternativně přístup na server přes *ssh*, na kterém běží
  PostgreSQL, na klientovi *psql*. Data stačí prohlížet přes
  webový prohlížeč (webový QGIS).
* `QGIS <http://www.qgis.org>`_ 3.4 a vyšší
* `PostGIS <http://www.postgis.net>`_ 3.0 a vyšší

.. only:: html

   Obsah
   =====

.. toctree::
   :maxdepth: 3

   kapitoly/0_uvod
   kapitoly/1_vytvarime_prostorovou_db
   kapitoly/2_tvorba_jednoduche_prostorove_tabulky
   kapitoly/3_shp2pgsql_a_davkove_nahrani
   kapitoly/4_prostorove_operatory
   kapitoly/5_prostorove_funkce
   kapitoly/6_obludy
   kapitoly/7_finty
   kapitoly/8_topologie
   kapitoly/9_rastry
   kapitoly/10_routing
   kapitoly/11_zaver

*******
Dodatky
*******

O dokumentu
===========

Text dokumentu je licencován pod `Creative Commons
Attribution-ShareAlike 4.0 International License
<http://creativecommons.org/licenses/by-sa/4.0/>`_.

.. figure:: images/cc-by-sa.png 
	    :width: 130px
	    :scale-latex: 120
              
*Verze textu dokumentu:* |release| (sestaveno |today|)

Autoři
------

Za `GISMentors <http://www.gismentors.cz/>`__:

* `Jan Michálek <http://www.gismentors.cz/mentors/michalek>`__ ``<godzilalalala gmail.com>``
* `Martin Landa <http://www.gismentors.cz/mentors/landa>`__ ``<martin.landa opengeolabs.cz>``
* `Jan Růžička <http://www.gismentors.cz/mentors/ruzicka>`_ ``<jan.ruzicka opengeolabs.cz>``

Text dokumentu
--------------

.. only:: latex

   Online HTML verze textu školení je dostupná na adrese:

   * http://training.gismentors.eu/postgis-pokrocily

Zdrojové texty školení jsou dostupné na adrese:

* https://github.com/GISMentors/postgis-pokrocily
