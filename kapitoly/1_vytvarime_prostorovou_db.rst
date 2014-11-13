Vytváříme prostorovou databázi
==============================
*Postgis rozšiřuje možnosti relační databáze* **PostgreSQL** *o ukládání, správu a dotazování prostorové informace. Po instalaci postgisu do databáze se objeví nové operátory, funkce, typy a některé nové relace. Postgisem je možné zpracovávat jak vektorová, tak rastrová data. Nad vektorovými daty lze vybudovat topologii a tu posléze dotazovat. Nejobvyklejším využitím je ovšem práce s jednoduchými prvky* **simple features.**

Tvorba prostorové databáze
--------------------------
K vytvoření prostorové databáze je nezbytný, postgis instalovaný na témže stroji, na které běží databázový server. K tomu poslouží balíčky v balíčkovacím systému vaší distribuce.

.. note:: V případě postgisu, i samotného PostgreSQL je výhodné používat up to date verze s ohledem na to, že vývoj odráží trendy v rychle se vyvíjejícím oboru a novější verze obsahují často velice užitečné *featury*, které často odráží aktuální požadavky. Proto je toto rozumné zohlednit při volbě distribuce pro provoz databázového serveru.

Prostorovou databázi je možné vytvořit několika způsoby. Pomocí skriptů, pomocí extenze a zkopírováním již existující databáze s postgisem.

Tvorba pomocí rozšíření
^^^^^^^^^^^^^^^^^^^^^^^

`Podrobný návod pro postgis 2.1 <http://postgis.net/docs/manual-2.1/postgis_installation.html#create_new_db_extensions>`_

Od **PostgreSQL** verze 9.1 můžeme vytvořit prostorovou databázi příkazem `CREATE EXTENSION`.

Instalace PostGIS pomocí *CREATE EXTENSION*
::

   $ psql pokusnik
   ...

   CREATE EXTENSION postgis;
   CREATE EXTENSION postgis_topology;

Velká výhoda tohoto postupu je snadný upgrade na vyšší verzi postgisu.
::

   ALTER EXTENSION postgis UPDATE TO "2.1.0";

Tvorba pomocí skriptů
^^^^^^^^^^^^^^^^^^^^^

`Kompletní postup pro postgis 2.1 <http://postgis.net/docs/manual-2.1/postgis_installation.html#create_new_db>`_

V některých případech není možné použít výše zmíněný postup kvůli staršímu postgrei, nastavení práv, nebo problémům s balíčky. Pak je možné provést tvorbu databáze `po staru` pomocí skriptů. Umístění skriptů se může lišit podle distribuce a verze postgisu.

.. notecmd:: dohledání instalačních skriptů PostGIS

   $ locate postgis.sql

   /home/jelen/jelen_dta/work/postgis_circle/postgis.sql

   /usr/share/postgresql/contrib/postgis-2.1/postgis.sql

   /usr/share/postgresql/contrib/postgis-2.1/rtpostgis.sql

   /usr/share/postgresql/contrib/postgis-2.1/uninstall_postgis.sql

   /usr/share/postgresql/contrib/postgis-2.1/uninstall_rtpostgis.sql

   $ 

.. notecmd:: instalace PostGIS pomocí skriptů

   psql -d db_s_postgis -f postgis.sql

   psql -d db_s_postgis -f spatial_ref_sys.sql

Vytvoříme postgis a naplníme tabulku souřadných systémů základní sadou předpřipravených SRS.

.. warning:: V základní sadě není obsaženo křovákovo zobrazení s v součanosti nejpoužívanějším SRID 5514, ale pouze starší verze. Tento systém je třeba doplnit ručně.

V tuto chvíli již máme vytvořenou plně funkční prostorovou databázi pro práci se *simple features*.

Ve složce se skripty jsou však některé další užitečné skripty, které stojí za to zmínit.

**postgis_comments.sql**
   Doplní k funkcím komentáře

**rtpostgis.sql, raster_comments.sql**
   Podpora a komentáře pro rastry

**topology.sql, topology_comments.sql**
   Nástroje na práci s topologií a komentáře

**legacy.sql**
   Zpětná kompatibilita.

Kopie již existující databáze s postgisem
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Pokud kopírujeme databázi, kopírujeme ji se vším všudy, je-li v ní nahrán postgis, kopírujeme ji i s ním.

.. important:: To samé platí, pochopitelně, i pro zálohování pomocí pg_dump. Proto je dobré u prostorových databází vytvářet pro pracovní data samostatné schéma a neukládat tato data do *public*. Kromě záležitostí souvisejících s nastavováním práv etc. totiž snadno oddělíte data od postgisu. Díky tomu jednak ušetříte místo při zálohování a přenosu souborů, ale hlavně si ušetříte mnohou nepříjemnost při přenosu dumpnutých dat na server s jinou verzí postgisu, nebo distribucí linuxu.

Postgre umožňuje kopírovat databázi použitím `template`.

Buď v psql (nebo pg_adminu - který je ovšem pro uplakánky):
::

   CREATE DATABASE moje_nova_databaze WITH TEMPLATE predem_pripravena_predloha;

Nebo pomocí příkazu `createdb`:
::

   createdb moje_nova_databaze -T predem_pripravena_predloha

Toho se využívalo u verzí PostgreSQL starších než 9.1 k tomu, že si správce databáze na serveru vytvořil prázdnou databázi s postgisem, aby se vyhnul otravnému vypisování skriptů.

Ovšem i u novějších verzí postgre má tato technika svoje opodstatnění. Obvykle v případě, že provádíme v databázi nějaké další upravy (přidané vlastní SRS ve *spatial_ref_sys*, přidané funkce, zásahy do kódování atp.)

Přidáváme vlastní SRS
---------------------

*Postgisu slouží k ukládání informací o souřadných systémech tabulka* **spatial_ref_sys** *v ní jsou uloženy definice souřadných systémů a primárním klíčem této tabulky je SRID. Do postgisu není možné vkládat geometri v souřadných systémech, které nejsou v tabulce spatial_ref_sys. Tuto tabulku je ovšem možno editovat, záznamy s definicemi upravovat, případně vkládat své vlastní.* 

Běžný datař se obvykle domnívá, že souřadné systémy se ho netýkají, že to je ten druh neštěstí, který obvykle potkává jiné lidi. To může a nemusí být pravda. Pokud budete pracovat s prvky, které mají geometrii všechny v témže souřadném systému, v kterém budete data do databáze nahrávat, ve kterém je budete publikovat a který už je defaultně obsažen ve spatial_ref_sys, nemusí Vás souřadné systémy nijak zvlášť postihnout.Pokud ovšem budete zpracovávat data v různých souřadných systémech a budete je chtít v databázi kombinovat, nevyhnete se setkání s nimi.

.. note:: Zde se nabízí lákavá možnost transformovat si prvky *vedle*, to však obvykle není výhodné řešení. Při každé transformaci totiž ztrácíme přesnost. Data se zkreslují, degenerují. Výjimku pochopitelně tvoří případy, kdy požadovanou transformaci nejsme schopní v databázi provést s náležitou přesností, případně pokud nám záleží na výkonu (je třeba si uvědomit, že prostorový index nad netransformovanými daty nemusí ve všech případech pracovat optimálně).

.. noteadvanced:: **Geometry vs geography** zde je asi na místě také pohovořit o dvou `geo` typech, které postgis nabízí. O typu geometry a geography. Geometry pracuje s projekcí na ploše, kdežto geography se zeměpisnými souřadnicemi, ve kterých provádí i měření a výpočty. V českém prostředí a křovákově zobrazení používáme vždy geometry. 

V defaultní sadě souřadných systémů schází křovákovo zobrazení :EPSG:`5514`, proto si ho do databáze doplníme.

.. notecmd:: přidání souřadného systému do databáze

   wget http://epsg.io/5514.sql

   psql -f 5514.sql moje_nova_databaze

.. noteadvanced:: Definice souřadných systémů umožňují využít zpřesňující klíče pro transformaci do wgs. Je záhodno tuto možnost využít, pokud máte v úmyslu data transformovat například do systému WGS84, nebo googlího mercatora. Trochu nešťastné ovšem je, že pro jeden souřadný systém je možné použít jen jednu sadu klíčů. Zároveň nefunguje žádná `dědičnost souřadných systémů`. Pokud tedy máte pokryté Česko i Slovensko a pro každý stát používáte 5514, pokaždé s jiným transformačním klíčem, nezbyde Vám, než nadefinovat si pro každý stát vlastní SRS s vlastním SRID.
