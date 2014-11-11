Dávkové nahrání dat
===================

*Dávkové zpracování a následné nahrávání dat z různých zdrojů do databáze je nejzákladnějším úkonem při budování databáze prostorových dat. Data obvykle nahráváme ze souborových formátů, případně z webových služeb. Řetězec úkonů mezi uchopením nějakého zdroje dat a jeho konečným umístěním do databáze bychom nejspíš označili termínem* **ETL**. *Pro standartní formáty s úspěchem můžeme využít utility knihovny gdal, jmenovitě* **ogr2ogr** *, pro import* **ESRI shapefile** *můžeme využít loader* **shp2pgsql** *instalovaný spolu s PostGISem.*

shp2pgsql
---------

**shp2pgsql** Je utilitka distribuovaná spolu s PostGISem. `Velice pěkně zpracovaný cheatsheet <http://www.bostongis.com/pgsql2shp_shp2pgsql_quickguide.bqg>`_. shp2pgsql vrací data v dump formátu a umí je poslat na standartní výstup. Je tedy možné, v případě potřeby prohnat výstup z této utility například přes sed, případně uložit do souboru a ručně zeditovat.

shp2pgsql umí jak data přidat do již existující tabulky, tak potřebnou tabulku vytvořit. Umí také pouze vytvořit tabulku podle souboru, aniž by do ní přidal data. Více v `manuálu <http://postgis.net/docs/manual-2.0/using_postgis_dbmanagement.html#shp2pgsql_usage>`_.

.. note:: Hlavním limitem pro použití shp2pgsql jsou samotné limity ESRI shapefile, které je zastaralé. Jda například o zakracování názvů sloupců. Také může bát problém s delšími celými čísly. Například numeric bude surově zakrácen na int, což může způsobit problémy mimo jiné u dat z ČUZAKu, které používají primární klíče numeric(30).

Nejdříve vyzkoušíme jednoduchý skript:
::

   shp2pgsql Ulice_cp1250.shp ukol_1.ulice | psql pokusnik 2> err

Tabulka se vůbec nevytvoří, problém je s kódováním. Dbf s numerikou je totiž v kódování cp1250 a naše databáze v UTF8. Použijeme proto přepínač -W pro nastavení kódování vstupního souboru.
::

   shp2pgsql -W cp1250 Ulice_cp1250.shp ukol_1.ulice | psql pokusnik 2> err

Pohled do geometry columns
::
       
   pokusnik=# select * from geometry_columns where f_table_schema = 'ukol_1';

+-----------------+----------------+--------------+-------------------+-----------------+--------+-----------------+
| f_table_catalog | f_table_schema | f_table_name | f_geometry_column | coord_dimension |  srid  |      type       |
+=================+================+==============+===================+=================+========+=================+
| pokusnik        | ukol_1         | ulice        | geom              |               2 |      0 | MULTILINESTRING |
+-----------------+----------------+--------------+-------------------+-----------------+--------+-----------------+

Nám odhalí poměrně nepříjemný fakt a to, že naše nově přidaná vrstva nemá správný souřadný systém (SRID 5514), nýbrž souřadný systém 0.

Musíme tedy rozšířit předešlý příkaz o zadání *SRID*, které má být nové vrstvě přiřazeno.
::

   shp2pgsql -W cp1250 -s 5514 Ulice_cp1250.shp ukol_1.ulice | psql pokusnik 2> err

.. note:: SRID vrstvy, je samozřejmě možné změnit u hotové vrstvy a to příkazem `UpdateGeometrySRID <http://postgis.net/docs/manual-2.0/UpdateGeometrySRID.html>`_, nicméně v případě, že nad takovou tabulkou už máte kupříkladu postavené pohledy, bude to neutně znamenat je všechny přegenerovat, přičemž si můžete (a také nemusíte) vyrobit nepříjemný chaos v právech. Je tedy jistě lepší na toto pamatovat a tabulky již vytvářet se správným SRID.

.. note:: K utilitě shp2pgsql existuje také obrácený nástroj **pgsql2shp** který slouží k exportu tabulek do ESRI shapefile. Jeho použití je jednoduché a najdete ho na každém stroji s postgisem. Na druhou stranu, ESRI shapefile je zastaralý formát a při jeho použití může dojít k degradaci dat, tudíž ho má smysl použít jen pokud příjemce dat vyžaduje výslovně tento formát.


Ogr2ogr
-------

Utilita `ogr2ogr <http://www.gdal.org/ogr2ogr.html>`_ je součástí balíku utilit distribuovaných s knihovnou **GDAL**. Slouží k převodu mezi drtivou většinou obvyklých formátů geodat. Mimo jiné, od verze 2.11 také VFR RUIAN, což je v našich podmínkách velice užitečné (potlesk pro Martina Landu). Kromě převodů mezi různými formáty geodat můžeme ogr2ogr použít i pro transformace mezi souřadnými systémy. Lze použít i transformaci podle gridu.

**ogr2ogr** se umí buď připojit rovnou do databáze, nebo umí generovat (případně posílat na *STDOUT*) data v *dump* formátu PostgreSQL.

Driver PostgreSQL
^^^^^^^^^^^^^^^^^

Nejdříve převedeme data z předešlého příkladu. Použijeme driver `PostgreSQL <http://www.gdal.org/drv_pg.html>`_, který se připojuje přímo k databázi.
::


   export SHAPE_ENCODING="cp1250"
   ogr2ogr -f PostgreSQL PG:dbname=pokusnik -a_srs 'EPSG:5514' Ulice_cp1250.shp \
      -nlt MULTILINESTRING \
      -nln ukol_1.ulice

V prvním řádku řekneme, v jakém kódování je zdrojový soubor shp.

.. note:: V případě, že bychom chtěli použít pro import jiné kódování, než je UTF8, nastavíme kódování pro PostgreSQL do proměnné prostředí **PGCLIENTENCODING**.

.. note:: Příkaz *export* funguje na linuxu, ve windows se proměnné prostředí nastavují `jinak <http://ss64.com/nt/syntax-variables.html>`_.

.. note:: Proměnnou prostředí **SHAPE_ENCODING** můžeme použít i v případě, že chceme použít při výstupu do **ESRI Shapefile** jiné kódování, než je UTF8.

Parametr **-f** nastaví výstupní formát na *PostgreSQL*, **PG:** nastaví `parametry připojení k databázi <http://www.postgresql.org/docs/9.4/interactive/libpq-connect.html>`_, je zde také možné nastavit aktivní schéma.

.. note:: U dávkového nahrávání je výhodné nastavit si heslo do `souboru s autentizací <http://www.postgresql.org/docs/9.4/static/libpq-pgpass.html>`_.

Parametr **-a_srs** slouží k nastavení výstupního souřadného systému, v tomto případě nastavíme souřadný systém na systém s *EPSG* 5514, tedy *křovákovo zobrazení*.

.. note:: Pokud bychom chtěli data v rámci importu transformovat použijeme proměnné **t_srs** a **s_srs**. Souřadný systém můžeme zadávat i v proj4 zápisu.

Následuje název vstupního souboru. Po něm je použit parametr **-nlt**, který slouží k zadání typu geometrie, v našem případě je to *MULTILINESTRING*, ogr2ogr totiž z nějakého důvodu v tomto případě chybně identifikuje geometrii vstupního souboru jako *LINESTRING*.

Nakonec pomoci **-nln** nastavíme nový název vrstvy (včetně názvu schématu, které ovšem musí být předem vytvořeno).


Driver PGDump
^^^^^^^^^^^^^

Driver `PGDump <http://www.gdal.org/drv_pgdump.html>`_ místo přímého spojení s databází zapisuje do souboru (nebo na *STDOUT*). To může být užitečné například v případě, že nemáme přímé připojení k databázi, nebo když chceme převedený soubor nějakým způsobem dále upravit. Můžeme ho například poslat rourou přes sed a potom rovnou na psql.

Zde přejmenujeme ulici *Kaštanová* na *Jírovcová*.
::

   export PG_USE_COPY=YES;
   ogr2ogr -f PGDump /dev/stdout -a_srs 'EPSG:5514' Ulice_cp1250.shp \
   -nlt MULTILINESTRING -nln ukol_1.ulice_3 \
   | sed 's/Kaštanová/Jírovcová/g' \
   | psql pokusnik 2> err

V prvním řádku nastavíme proměnnou prostředí **PG_USE_COPY**. Tím řekneme, že data mají být přenesena jako *COPY tabname FROM STDIN*, namísto řady *INSERT* statementů. Stejným způsobem by fungoval i *PostgrSQL** driver. 

Parametry na dalším řádku již známe. Jedná se o formát, následuje název výstupního souboru (v našem případě odesíláme na stdout), výstupní souřadný systém a vstupní soubor. Další řádek též nepřináší nic nového. Nakonec nahradíme pomocí sedu "Kaštanová" za "Jírovcová" a odešleme rourou na psql.

.. note:: PostgreSQL driver může mít problém vytvořit tabulku s více geometrickými sloupci, potom nezbývá než použít PGDump driver, nebo vytvořit tabulku ručně.

Samozřejmě *ESRI shapefile* není jediný formát, se kterým ogr2ogr pracuje. Předvedeme si, jak snadno nahrát soubor v **GML**.
::

   ogr2ogr -f PGDump /dev/stdout -a_srs 'EPSG:5514' adres_mista.gml -nln ukol_1.adresy_1 | psql pokusnik 2> err

V ogr2ogr je možné pracovat i s webovými službami, například můžeme načíst katastrální území z `WFS ČUZAKu <http://services.cuzk.cz/doc/inspire-cp-view.pdf>`_.
::

   ogr2ogr -f "PostgreSQL" PG:"dbname=pokusnik" \
   "http://services.cuzk.cz/wfs/inspire-cp-wfs.asp?\
   service=WFS\
   &request=GetFeature&version=2.0.0\
   &srsName=urn:ogc:def:crs:EPSG::5514\
   &typeNames=CP:CadastralZoning\
   &featureid=CZ.605999" \
   -nln ukol_1.katatest

Ve WFS bývá zhusta limit na maximální počet prvků, není tedy, v praxi, možné obvykle stáhnout větší objem dat. Můžeme však stahovat prvky po jednom. Z `číselníku katastrálních území <http://www.cuzk.cz/CUZK/media/CiselnikyISKN/SC_SEZNAMKUKRA_DOTAZ/SC_SEZNAMKUKRA_DOTAZ.zip?ext=.zip>`_ vybereme katastry Prahy.
::

   wget http://www.cuzk.cz/CUZK/media/CiselnikyISKN/SC_SEZNAMKUKRA_DOTAZ/SC_SEZNAMKUKRA_DOTAZ.zip?ext=.zip
   unzip SC_SEZNAMKUKRA_DOTAZ.zip?ext=.zip
   psql -c "truncate table ukol_1.katatest" pokusnik;

   cut -d ';' -f 7,8 SC_SEZNAMKUKRA_DOTAZ.csv | \
      tail -n +2 | \
      cut -d ';' -f 2 | while read kodku; do
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

.. note:: Bagrování WFS ovšem není ideální způsob jak plnit daty databázi (limit na bbox a po4et prvk; tam nen9 jen tak pro nic za nic). Tato data je možné získat i pohodlněji a šetrněji k infrastruktuře ČUZAKu.

Na závěr si naše data zobrazíme v **SVG**.
::

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
