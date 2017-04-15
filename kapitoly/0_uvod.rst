Úvod
====

**PostGIS** rozšiřuje možnosti relační databáze `PostgreSQL
<http://www.postgresql.org>`_ o ukládání, správu a dotazování
geografické (prostorové) informace. Po instalaci rozšíření PostGIS do
databáze jsou dostupné nové operátory, funkce, typy a relace. Pomocí
PostGISu je možné zpracovávat jak vektorová, tak rastrová data. Nad
vektorovými daty lze dokonce vybudovat topologii a dotazovat se na
ni. Nejobvyklejším využitím je ovšem práce s jednoduchými prvky,
tzv. *simple features*, viz :skoleni:`školení pro začátečníky
<postgis-zacatecnik/kapitoly/1_uvod#prostorova_db>`.

Obecná doporučení
-----------------

Začneme několika obecnými doporučeními. Vesměs se jedná o samozřejmé
věci. Domníváme se nicméně, že stojí za to si je připomenout.

Indexujte
^^^^^^^^^

Indexujte, pokud nebudete používat indexy, je skoro jedno, jestli
budete ukládat data do databáze, nebo jen tak, do textových
souborů. Index si můžeme představit jako rejstřík u knihy, pokud kniha
nemá rejstřík, jediný způsob, jak najít nějakou informaci, je pročítat
knihu, dokud požadované údaje nenajdeme.  U PostgreSQL navíc (až na
výjimky) platí, že musí načíst z datové stránky celý záznam, aby se
dobralo hodnoty konkrétní položky.

Od jakého množství záznamů se vyplatí tabulky indexovat záleží na mnoha věcech.
Na typu dat, výkonu hardware, nastavení PostgreSQL. Při velké míře zobecnění se
dá říct, že indexovat má cenu tabulky od velikosti několika tisíc záznamů.

Geometrické hodnoty indexujte :pgsqlcmd:`GiST indexem <gist>`. Číselné hodnoty a
řetězce obvykle pomocí :pgsqlcmd:`b-tree indexu <indexes-types>`.

.. noteadvanced:: Zda byl index použit v konkrétním dotazu můžeme zjistit pomocí
                  klauzule `EXPLAIN
                  <https://www.postgresql.org/docs/current/static/sql-explain.html>`_,
                  která zobrazí prováděcí plán. Kolikrát byl index skutečně
                  použit zjistíme dotazem do systémového katalogu
                  `pg_stat_all_indexes
                  <https://www.postgresql.org/docs/current/static/monitoring-stats.html#PG-STATIO-ALL-INDEXES-VIEW>`_.

Používejte transakce
^^^^^^^^^^^^^^^^^^^^

Transakce jsou neprávem považovány za jakýsi "databázistický folklór"
spojený s tím otřepaným povídáním o částce, která musí být zároveň
přidána na jeden bankovní účet a odebrána z druhého. Transakce mají
však podstatně širší využítí. Obzvlášť pokud zasahujete do datových
struktur s komplikovanými vazbami, může vám použití transakcí ušetřit
mnoho práce s napravováním paseky v datech. Nemluvě o tom, že pokud
jste v transakci, nemusíte se bát, že něco pokazíte, dokud
neodkliknete COMMIT. Můžete tedy provést změny, otestovat pár dotazů,
jestli se všechno chová jak má a teprve pak potvrdit změny v databázi.

Na druhou stranu je ovvšem třeba pamatovat na to, že neukončená transakce může
zamknout tabulky a znemožnit ostatním uživatelům efektivně pracovat s databází.

.. noteadvanced:: Vzájemná izolace transakcí při současném zápisu je realizovaná
                  prostřednictvím `multigenerační architektury
                  <http://postgres.cz/wiki/Slovník#MVCC>`_.

Věnujte dostatečnou pozornost návrhu struktur
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Velkou chybou je podcenění návrhu databázových struktur. Čas
investovaný do návrhu datového modelu se vám mnohonásobně
vrátí. Převést data z nedostačující struktury je navíc obvykle velmi
pracné a nese sebou riziko poškození dat.

Nalaďte si PostgreSQL
^^^^^^^^^^^^^^^^^^^^^

Je třeba si uvědomit, že PostgreSQL je objektově relační databázový
systém (systém pro řízení báze dat). Ukládání dat do databáze se v
mnohém liší od ukládání dat do souborů. K dosažení maximální
efektivity je třeba PostgreSQL správně nastavit. Rozdíl v rychlosti
mezi správně nastavenou databází a výchozím nastavením může
být klidně o několik řádů. PostgreSQL se nastavuje jednak s ohledem na
hardware a jednak i s ohledem na požadované využití (předpokládaný
počet paralelně připojených uživatelů, velikost tabulek
atd.). Nastavení se provádí ručně a je netriviální. Pokud uděláte
zásadní chybu, hrozí havárie a to včetně rizika poškození dat. Pokud
se na to necítíte nebo nevíte přesně co děláte, je rozumné si nechat
poradit.

Základní úvod do problematiky je možné nabýt třeba `zde
<http://www.linuxexpres.cz/praxe/optimalizace-postgresql>`_.

.. note:: Základní nastavení PostgreSQL po instalaci je obvykle velice šetrné ke
          zdrojům, na úkor výkonu. Je to proto, aby bylo možné PostgreSQL pustit
          i na nevýkonném počítači bez rizika havárie systému. Základní
          nastavení je možné provést pomocí nástroje `pgTune <http://pgfoundry.org/projects/pgtune/>`_,
          které přizpůsobí nastavení PostgreSQL výkonu Vašeho hardware.

Naučte se používat psql
^^^^^^^^^^^^^^^^^^^^^^^

Psql je konzolový klient pro PostgreSQL, přestože působí poněkud
spartánsky, jedná se o nástroj se kterým je možné dosáhnout největší
efektivity. Specialitou jsou tzv. metapříkazy. Použití psql v
příkazové řádce či skriptech je velice mocná kombinace.

Kdy je výhodnější použít jiný nástroj
-------------------------------------

Je třeba si uvědomit, že PostGIS není analytický nástroj, ale
rozšíření databáze. Přestože v něm jde vyřešit drtivá většina úloh, se
kterými se můžeme ve své praxi setkávat, ne vždy se jedná o řešení
nejjednodušší, nejelegantnější a nejsprávnější. Vzhledem k tomu, že
PostGIS samotný pracuje se *simple features*, tj. jednoduchými geoprvky
(ačkoliv existuje i rozšíření :doc:`Topology <8_topologie>`), je využití PostGISu pro
analytické úlohy do jisté míry limitováno možnostmi jednoduchých
prvků. Dost velká omezení přináší také práce s velkými (co do množství
lomových bodů) prvky nebo prvky hodně členitými.
