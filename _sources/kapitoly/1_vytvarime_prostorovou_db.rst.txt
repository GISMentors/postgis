Vytváříme prostorovou databázi
==============================

Je nezbytné, aby byl PostGIS nainstalován na témže stroji, na kterém
běží databázový server. K tomu poslouží balíčky v balíčkovacím systému
vaší distribuce. Návod pro operační systém Windows :skoleni:`zde
<postgis-zacatecnik/kapitoly/7_instalace.html>`.

.. note:: V případě PostGIS a PostgreSQL je výhodné používat
          nejnovější verze s ohledem na to, že odráží trendy v rychle
          se vyvíjejícím oboru. Novější verze obsahují velice užitečné
          *featury*, které často odráží aktuální požadavky. Proto je
          rozumné toto zohlednit při volbě distribuce pro provoz
          vašeho databázového serveru.

Tvorba prostorové databáze
--------------------------

Prostorovou databázi je možné vytvořit několika způsoby. Pomocí
skriptů, extenze (rozšíření) či zkopírováním již existující prostorové
databáze.

Tvorba pomocí rozšíření
^^^^^^^^^^^^^^^^^^^^^^^

*Od PostgreSQL verze 9.1* můžeme vytvořit prostorovou databázi
příkazem ``CREATE EXTENSION``, viz `podrobný návod pro PostGIS 2.1
<http://postgis.net/docs/manual-2.1/postgis_installation.html#create_new_db_extensions>`_.

Postup instalace PostGIS pomocí *CREATE EXTENSION*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. notecmd:: Spuštění psql

   V tomto případě předpokládáme existenci databáze `pokusnik`.
             
	.. code-block:: bash

		psql pokusnik

.. code-block:: sql

   CREATE EXTENSION postgis;

Velká výhoda tohoto postupu je snadný upgrade na vyšší verzi PostGISu,
viz příklad níže.

.. code-block:: sql

   ALTER EXTENSION postgis UPDATE TO "2.1.0";

.. noteadvanced:: V případě, že máme databázi přemigrovanou z nějaké starší
                  verze, kdy postgis nebyl instalován prostřednictvím extenze,
                  je možné požít dotaz :sqlcmd:`CREATE EXTENSION postgis FROM
                  unpackaged`. Což předpokládá, že máte postgis v odpovídající
                  verzi, v opačném případě se to nemusí podařit. Jinou možností,
                  jak přiřadit funkce k extenzi je dotaz :sqlcmd:`ALTER
                  EXTENSION postgis ADD ...`.

Instalace rozšíření pomocí extenze také umožňuje nahrát rozšíření do vybraného
schéma (defaultně je to obvykle public), což může být praktické, pokud budete
chtít zálohovat databázi pomocí :pgsqlcmd:`pg_dump <app-pgdump>` bez postgisu
a budete chtít, z nějakého důvodu, ukládat do *public* nějaká svá data.

Tvorba pomocí skriptů
^^^^^^^^^^^^^^^^^^^^^

V některých případech není možné použít výše zmíněný postup kvůli
starší verzi PostgreSQL, nastavení práv nebo problémům s balíčky. Pak
je možné provést tvorbu databáze `po staru` pomocí skriptů. Umístění
skriptů se může lišit podle distribuce a verze PostGISu, viz `podrobný
postup pro PostGIS 2.1
<http://postgis.net/docs/manual-2.1/postgis_installation.html#create_new_db>`_.

.. notecmd:: Dohledání instalačních skriptů PostGIS

   .. code-block:: bash

      locate postgis.sql

   ::

      /usr/share/postgresql/contrib/postgis-2.1/postgis.sql
      /usr/share/postgresql/contrib/postgis-2.1/rtpostgis.sql
      /usr/share/postgresql/contrib/postgis-2.1/uninstall_postgis.sql
      /usr/share/postgresql/contrib/postgis-2.1/uninstall_rtpostgis.sql

.. notecmd:: Instalace PostGIS pomocí skriptů

   PostGIS nainstalujeme a naplníme tabulku souřadnicových
   systémů základní sadou předpřipravených :abbr:`SRS (Spatial
   Reference Systems)`.
   
   .. code-block:: bash
                   
      psql -d db_s_postgis -f postgis.sql
      psql -d db_s_postgis -f spatial_ref_sys.sql

.. warning:: V základní sadě nemusí být obsažena nejnovější definice
             souřadnicového systému S-JTSK (:epsg:`5514`), ale pouze
             jeho starší verze. Tento souřadnicový systém je třeba
             :ref:`doplnit ručně <epsg-5514>`.

V tuto chvíli již máme vytvořenu plně funkční prostorovou databázi pro
práci s vektorovými daty ve formě tzv. *simple features*.

Ve složce se skripty jsou však některé další užitečné skripty, které
stojí za to zmínit.

*postgis_comments.sql*
   Doplní k funkcím komentáře

*rtpostgis.sql, raster_comments.sql*
   Podpora a komentáře pro rastrovými daty

*topology.sql, topology_comments.sql*
   Nástroje na práci s topologií vektorových dat a komentáře

*legacy.sql*
   Zpětná kompatibilita.

Kopie již existující databáze
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Pokud kopírujeme databázi, kopírujeme ji se vším všudy, je-li v ní
nahrán PostGIS, kopírujeme ji i s ním.

.. important:: To samé platí, pochopitelně, i pro zálohování pomocí
               *pg_dump*. Proto je dobré u prostorových databází
               vytvářet pro pracovní data samostatné schéma a
               neukládat tato data do *public*. Kromě záležitostí
               souvisejících s nastavováním práv a pod. totiž snadno
               oddělíte data od samotného PostGISu. Díky tomu jednak
               ušetříte místo při zálohování a přenosu souborů, ale
               hlavně si ušetříte mnohou nepříjemnost při přenosu
               vyexportovaných dat na server s jinou verzí PostGISu
               nebo distribucí Linuxu.

PostgreSQL umožňuje kopírovat databázi pomocí parametru
:option:`template`.

Buď v :program:`psql` nebo :program:`pgAdminIII`:

.. code-block:: sql

   CREATE DATABASE moje_nova_databaze WITH TEMPLATE predem_pripravena_predloha;

Nebo pomocí příkazu `createdb`:

.. notecmd:: Kopírování databáze

	.. code-block:: bash

		createdb moje_nova_databaze -T predem_pripravena_predloha

.. note:: Toho se využívalo u verzí PostgreSQL starších než 9.1 k
          tomu, že si správce databáze na serveru vytvořil prázdnou databázi s
          PostGISem jako šablonu pro další databáze tak, aby se vyhnul otravnému
          vypisování skriptů.

          Ovšem i u novějších verzí PostgreSQL má tato technika svoje
          opodstatnění. Obvykle v případě, že provádíme v databázi nějaké další
          upravy (přidané vlastní SRS ve *spatial_ref_sys*, přidané funkce,
          zásahy do kódování atp.)

U vytváření prostorové databáze podle *TEMPLATE* je ale dobré vědět, že ssebou
nese určitá omezení. Jedním z těch podstatných je nastavení *LOCALES*, které je
možné použít pouze s :sqlcmd:`TEMPLATE template0`. Pokud tedy chcete pracovat s
daty, která obsahují interpunkci, nebo nějaké národní sady znaků, je třeba
udělat již předlohu se správným *LC_COLLATE* a *LC_CTYPE*, jinak nebudou některé
funkce (například *lower*, *upper*, *unaccent*) fungovat správně.

Přidáváme vlastní SRS
---------------------

Informace o souřadnicových systémech ukládá PostGIS v tabulce
:dbtable:`spatial_ref_sys`. Primárním klíčem této tabulky je SRID.

.. note:: Do PostGISu není možné vkládat geometrii v souřadnicových
          systémech, které nejsou uvedeny v tabulce
          :dbtable:`spatial_ref_sys`. Tuto tabulku je ovšem možno
          editovat, záznamy s definicemi upravovat, případně vkládat
          své vlastní.

Běžný datař se obvykle domnívá, že souřadnicové systémy se ho
netýkají, že to je ten druh neštěstí, který obvykle potkává
jiné lidi. To může a nemusí být pravda. Pokud budete pracovat s daty,
které jsou definovány v témže souřadnicovém systému, jak v
originálních datech, tak v databázi a případě při publikaci dat a
tento souřadnicový systém je již obsažen v tabulce
:dbtable:`spatial_ref_sys`, nemusí vás souřadnicové systémy nijak
zvlášť zajímat. Pokud ovšem budete zpracovávat data v různých
souřadnicových systémech a budete je chtít v databázi kombinovat, tak
se jim nevyhnete.

.. note:: Zde se nabízí lákavá možnost transformovat si prvky před importem.
          To však nemusí být vždy nejvýhodnější řešení. Při každé
          transformaci totiž ztrácíme přesnost. Data se zkreslují,
          degenerují. Výjimku pochopitelně tvoří případy, kdy
          požadovanou transformaci nejsme schopní v databázi provést s
          náležitou přesností, případně pokud nám záleží na výkonu (je
          třeba si uvědomit, že prostorový index nad
          netransformovanými daty nemusí ve všech případech pracovat
          optimálně).

.. noteadvanced:: **Geometry vs geography** PostGIS podporuje dva
                  datové typy pro uložení geometrie geoprvků, geometry
                  a geography. Geometry pracuje s plošným
                  kartografickým zobrazením, kdežto geography se
                  zeměpisnými souřadnicemi, ve kterých provádí i
                  měření a výpočty. V českém prostředí v souvislosti
                  se souřadnicovým systémem S-JTSK používáme vždy
                  geometry.

V výchozí sadě souřadnicových systémů může chybět nejnovější definice
souřadnicového systému S-JTSK :EPSG:`5514`, proto si ho do databáze
doplníme.

.. _epsg-5514:

.. notecmd:: Přidání souřadnicového systému S-JTSK do databáze

	.. code-block:: bash

		wget http://epsg.io/5514.sql
		psql -f 5514.sql moje_nova_databaze

.. noteadvanced:: Definice souřadnicových systémů umožňují využít
                  zpřesňující klíče pro transformaci do WGS-84 (GPS,
                  zeměpisné souřadnice). Pokud transformační klíče
                  budete ignorovat, dopustíte se při transformaci dat
                  z S-JTSK do jiného systému chyby, která může
                  dosahovat až několika desítek metrů. Trochu
                  nešťastné ovšem je, že pro jeden souřadnicový systém
                  je možné použít pouze jednu sadu transformačních
                  klíčů. Zároveň nefunguje žádná `dědičnost
                  souřadnicových systémů`. Pokud tedy pracujete s daty
                  pokrývající ČR a Slovensko, použijete v obou
                  případech :epsg:`5514`, pokaždé ale s jiným
                  transformačním klíčem. Pro každý stát si tedy budete
                  muset nadefinovat vlastní SRS odvozené z SRID 5514
                  doplněné transformačním klíčem. Alternativou k
                  transformačním klíčům jsou gridy, které poskytují
                  vzhledem ke své podrobnosti přesnější výsledky při
                  transformaci dat.
