Dávkové nahrání dat
===================

*Dávkové zpracování a následné nahrávání dat z různých zdrojů do databáze je nejzákladnějším úkonem při budování databáze prostorových dat. Data obvykle nahráváme ze souborových formátů, případně z webových služeb. Řetězec úkonů mezi uchopením nějakého zdroje dat a jeho konečným umístěním do databáze bychom nejspíš označili termínem* **ETL**. *Pro standardní formáty s úspěchem můžeme využít utility knihovny* `GDAL <http://gdal.org>`_, *jmenovitě* `ogr2ogr <http://www.gdal.org/ogr2ogr.html>`_, *pro import* :wikipedia-en:`Esri shapefile` *můžeme využít loader shp2pgsql instalovaný spolu s PostGISem.*

shp2pgsql
---------

`shp2pgsql <http://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg>`_ je utilitka distribuovaná spolu s PostGISem, která vrací data v dump formátu na standardní výstup. Je tedy možné, v případě potřeby, upravit výstup z této utility například unixovým nástrojem ``sed`` či případně uložit do souboru a ručně zeditovat.

shp2pgsql umí jak data přidat do již existující tabulky, tak potřebnou tabulku vytvořit. Lze také pouze vytvořit na základě dat prázdnou tabulku a samotná data do ní nenahrávat. Více v `manuálu <http://postgis.net/docs/using_postgis_dbmanagement.html#shp2pgsql_usage>`_.

.. note:: Hlavním limitem pro použití shp2pgsql jsou samotné limity formátu Esri Shapefile. Jde například o zkracování názvů sloupců, formát nedovoluje délku názvu sloupce větší než 10 znaků. Dále můžete mít problém s některými datovými typy, například ``numeric`` bude surově zakrácen na ``int``, což může způsobit problémy mimo jiné u dat ve formátu VFK, které používají primární klíče ``numeric(30)``.

V našem příkladě zkusíme nahrát `datovou vrstvu ulic <http://training.gismentors.eu/geodata/postgis/Ulice_cp1250.zip>`_.

.. code-block:: bash

   shp2pgsql Ulice_cp1250.shp ukol_1.ulice | psql pokusnik 2> err

Tabulka se vůbec nevytvoří, problém je s kódováním. Atributová tabulka vstupních dat je v kódování cp1250 a naše databáze v UTF8. Použijeme proto přepínač :option:`-W` pro nastavení kódování vstupního souboru.

.. code-block:: bash

   shp2pgsql -W cp1250 Ulice_cp1250.shp ukol_1.ulice | psql pokusnik 2> err

Pohled do :dbtable:`geometry_columns` nám odhalí poměrně nepříjemný fakt a to, že naše nově přidaná vrstva nemá správný souřadnicový systém (SRID 5514), nýbrž neznámý souřadnicový systém s kódem 0.

.. code-block:: sql
       
   SELECT * FROM geometry_columns WHERE f_table_schema = 'ukol_1';

::

   f_table_catalog   | skoleni
   f_table_schema    | ukol_1
   f_table_name      | ulice
   f_geometry_column | geom
   coord_dimension   | 2
   srid              | 0
   type              | MULTILINESTRING

Musíme tedy rozšířit předešlý příkaz o zadání *SRID*, které má být nové vrstvě přiřazeno (přídáme přepínačý :option:`-d`, který stavající tabulku nejprve odstraní).

.. code-block:: bash

   shp2pgsql -d -W cp1250 -s 5514 Ulice_cp1250.shp ukol_1.ulice | psql pokusnik 2> err

.. tip:: SRID vrstvy, je samozřejmě možné změnit u hotové vrstvy a to příkazem :pgiscmd:`UpdateGeometrySRID`, nicméně v případě, že nad takovou tabulkou už máte kupříkladu postavené pohledy, bude to nutně znamenat je všechny přegenerovat, přičemž si můžete (a také nemusíte) vyrobit nepříjemný chaos v právech. Je tedy lepší na toto pamatovat a tabulky již vytvářet se správným SRID.

.. tip:: K utilitě shp2pgsql existuje také obrácený nástroj **pgsql2shp**, který slouží k exportu tabulek do formátu Esri Shapefile. Jeho použití je jednoduché a najdete ho na každém stroji s PostGISem. Nicméně, jak již bylo zmíněno, Esri Shapefile je zastaralý formát. Při jeho použití může dojít k degradaci dat, tudíž ho má smysl použít jen pokud příjemce dat vyžaduje výslovně tento formát.


Ogr2ogr
-------

Utilita `ogr2ogr <http://www.gdal.org/ogr2ogr.html>`_ je součástí balíku utilit distribuovaných s knihovnou **GDAL**. Slouží k převodu mezi drtivou většinou obvyklých formátů geodat. Mimo jiné, od verze 2.11 také VFR RUIAN, což je v našich podmínkách velice užitečné (potlesk pro Martina Landu). Kromě převodů mezi různými formáty geodat můžeme ogr2ogr použít i pro transformace mezi souřadnými systémy. Lze použít i transformaci podle gridu.

**ogr2ogr** se umí buď připojit rovnou do databáze, nebo umí generovat (případně posílat na *STDOUT*) data v *dump* formátu PostgreSQL.

Driver PostgreSQL
^^^^^^^^^^^^^^^^^

Nejdříve převedeme data z předešlého příkladu. Použijeme driver `PostgreSQL <http://www.gdal.org/drv_pg.html>`_, který se připojuje přímo k databázi.

.. notecmd:: nahrání **ESRI shapefile** pomocí ogr2ogr

   .. code-block:: bash

      export SHAPE_ENCODING="cp1250"
      ogr2ogr -f PostgreSQL PG:dbname=pokusnik -a_srs 'EPSG:5514' Ulice_cp1250.shp \
	 -nlt MULTILINESTRING \
	 -nln ukol_1.ulice

V prvním řádku řekneme, v jakém kódování je zdrojový soubor shp.

.. tip:: V případě, že bychom chtěli použít pro import jiné kódování, než je UTF8, nastavíme kódování pro PostgreSQL do proměnné prostředí **PGCLIENTENCODING**.

.. warning:: Příkaz *export* funguje na linuxu, ve windows se proměnné prostředí nastavují `jinak <http://ss64.com/nt/syntax-variables.html>`_.

.. tip:: Proměnnou prostředí **SHAPE_ENCODING** můžeme použít i v případě, že chceme použít při výstupu do **ESRI Shapefile** jiné kódování, než je UTF8.

Parametr :option:`-f` nastaví výstupní formát na *PostgreSQL*, :option:`PG:` nastaví `parametry připojení k databázi <http://www.postgresql.org/docs/9.4/interactive/libpq-connect.html>`_, je zde také možné nastavit aktivní schéma.

.. tip:: U dávkového nahrávání je výhodné nastavit si heslo do `souboru s autentizací <http://www.postgresql.org/docs/9.4/static/libpq-pgpass.html>`_.

Parametr :option:`-a_srs` slouží k nastavení výstupního souřadného systému, v tomto případě nastavíme souřadný systém na systém s *EPSG* 5514, tedy *křovákovo zobrazení*.

.. noteadvanced:: Pokud bychom chtěli data v rámci importu transformovat použijeme proměnné :option:`t_srs` a :option:`s_srs`. Souřadný systém můžeme zadávat i v proj4 zápisu.


Následuje název vstupního souboru. Po něm je použit parametr :option:`-nlt`, který slouží k zadání typu geometrie, v našem případě je to *MULTILINESTRING*, ogr2ogr totiž z nějakého důvodu v tomto případě chybně identifikuje geometrii vstupního souboru jako *LINESTRING*.

Nakonec pomoci :option:`-nln` nastavíme nový název vrstvy (včetně názvu schématu, které ovšem musí být předem vytvořeno).


Driver PGDump
^^^^^^^^^^^^^

Driver `PGDump <http://www.gdal.org/drv_pgdump.html>`_ místo přímého spojení s databází zapisuje do souboru (nebo na *STDOUT*). To může být užitečné například v případě, že nemáme přímé připojení k databázi, nebo když chceme převedený soubor nějakým způsobem dále upravit. Můžeme ho například poslat rourou přes sed a potom rovnou na psql.

Zde přejmenujeme ulici *Kaštanová* na *Jírovcová*.

.. notecmd:: nahrání **ESRI shapefile** pomocí ogr2ogr

   .. code-block:: bash

      export PG_USE_COPY=YES;
      ogr2ogr -f PGDump /dev/stdout -a_srs 'EPSG:5514' Ulice_cp1250.shp \
      -nlt MULTILINESTRING -nln ukol_1.ulice_3 \
      | sed 's/Kaštanová/Jírovcová/g' \
      | psql pokusnik 2> err

V prvním řádku nastavíme proměnnou prostředí :option:`PG_USE_COPY`. Tím řekneme, že data mají být přenesena jako *COPY tabname FROM STDIN*, namísto řady *INSERT* statementů. Stejným způsobem by fungoval i *PostgrSQL** driver. 

Parametry na dalším řádku již známe. Jedná se o formát, následuje název výstupního souboru (v našem případě odesíláme na stdout), výstupní souřadný systém a vstupní soubor. Další řádek též nepřináší nic nového. Nakonec nahradíme pomocí sedu "Kaštanová" za "Jírovcová" a odešleme rourou na psql.

.. important:: PostgreSQL driver může mít problém vytvořit tabulku s více geometrickými sloupci, potom nezbývá než použít PGDump driver, nebo vytvořit tabulku ručně.

Samozřejmě *ESRI shapefile* není jediný formát, se kterým ogr2ogr pracuje. Předvedeme si, jak snadno nahrát soubor v **GML**.

.. notecmd:: nahrání **GML** pomocí ogr2ogr

   .. code-block:: bash

      ogr2ogr -f PGDump /dev/stdout -a_srs 'EPSG:5514' \
      adres_mista.gml \
      -nln ukol_1.adresy | \
      psql pokusnik 2> err

V ogr2ogr je možné pracovat i s webovými službami, například můžeme načíst katastrální území z `WFS ČUZAKu <http://services.cuzk.cz/doc/inspire-cp-view.pdf>`_.

.. notecmd:: nahrání WFS

   .. code-block:: bash

      ogr2ogr -f "PostgreSQL" PG:"dbname=pokusnik" \
      "http://services.cuzk.cz/wfs/inspire-cp-wfs.asp? \
      service=WFS \
      &request=GetFeature&version=2.0.0 \
      &srsName=urn:ogc:def:crs:EPSG::5514 \
      &typeNames=CP:CadastralZoning \
      &featureid=CZ.605999" \
      -nln ukol_1.katatest

Ve WFS bývá zhusta limit na maximální počet prvků, není tedy, v praxi, možné obvykle stáhnout větší objem dat. Můžeme však stahovat prvky po jednom. Z `číselníku katastrálních území <http://www.cuzk.cz/CUZK/media/CiselnikyISKN/SC_SEZNAMKUKRA_DOTAZ/SC_SEZNAMKUKRA_DOTAZ.zip?ext=.zip>`_ vybereme katastry Prahy.

.. notecmd:: dávkového nahrání dat z WFS

   .. code-block:: bash

      wget http://www.cuzk.cz/CUZK/media/CiselnikyISKN/SC_SEZNAMKUKRA_DOTAZ/SC_SEZNAMKUKRA_DOTAZ.zip?ext=.zip
      unzip SC_SEZNAMKUKRA_DOTAZ.zip?ext=.zip
      psql -c "truncate table ukol_1.katatest" pokusnik;

      cut -d ';' -f 7,8 SC_SEZNAMKUKRA_DOTAZ.csv | \
	 tail -n +2 | \
	 grep Praha |
	 cut -d ';' -f 2 |
	 while read kodku; do
	    echo $kodku;
	    ogr2ogr -append \
	    -f "PostgreSQL" PG:"dbname=pokusnik" \
	    "http://services.cuzk.cz/wfs/inspire-cp-wfs.asp?\
      service=WFS\
      &request=GetFeature&version=2.0.0\
      &srsName=urn:ogc:def:crs:EPSG::5514\
      &typeNames=CP:CadastralZoning&\
      featureid=CZ.$kodku" \
	    -nln ukol_1.katatest
	 done;

.. warning:: Bagrování WFS ovšem není ideální způsob jak plnit daty databázi (limit na bbox a počet prvků tam není jen tak pro nic za nic). Tato data je možné získat i pohodlněji a šetrněji k infrastruktuře ČUZAKu.

Na závěr si naše data zobrazíme v **SVG**.

.. code-block:: sql

   SET SEARCH_PATH = public, ukol_1;
   SELECT 
   XMLELEMENT(
      NAME svg, 
      XMLATTRIBUTES(
         height, width, "viewBox"
         , 'http://www.w3.org/2000/svg' AS xmlns, '1.1' AS version)
      , linie, body, popisky
   )
   FROM
   (
      SELECT
      600 AS height
      , 800 AS width
      , array_to_string(ARRAY[MIN(ST_XMIN(geom)) - 50, -1 * (MAX(ST_YMAX(geom))) - 50
         , (@(MAX(ST_XMAX(geom)) - MIN(ST_XMIN(geom)))) + 100
         , (@(MAX(ST_YMAX(geom)) - MIN(ST_YMIN(geom)))) + 100], ' ') AS "viewBox"
      , XMLAGG(
         XMLELEMENT(NAME path, 
            XMLATTRIBUTES( ST_AsSVG(geom, 1, 0) AS d
               , 'rgb(55,230,100)' AS stroke
               , 25 AS "stroke-width"
               , 'none' AS fill
            )
         )
      ) linie
      FROM 
      (
         SELECT wkb_geometry AS geom FROM ulice --LIMIT 1
      ) ok
   ) podklad,
   (
      SELECT
      XMLAGG(
         XMLELEMENT(NAME circle, 
            XMLATTRIBUTES( ST_X(geom) AS cx, -1 * ST_Y(geom) AS cy, 150 AS r 
               , 'black' AS stroke
               , 100 AS "stroke-width"
               , 'rgb(255,0,0)' AS fill
            )
         )
      ) body

      , XMLAGG(
         XMLELEMENT(NAME text, 
            XMLATTRIBUTES( ST_X(geom) + 250 AS x, -1 * ST_Y(geom) AS y
               , 'Verdana' AS "font-family"
               , 750 AS "font-size"
               , 'rgb(0,0,0)' AS fill
            ), id
         )
      ) popisky
      FROM 
      (
         SELECT id, geom_p AS geom FROM vesmirne_zrudice --LIMIT 1
      ) body
   ) data;
