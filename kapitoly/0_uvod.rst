Úvod
====

**PostGIS** rozšiřuje možnosti relační databáze *PostgreSQL* o
ukládání, správu a dotazování geografické (prostorové) informace. Po
instalaci PostGISu do databáze jsou dostupné nové operátory, funkce,
typy a relace. Pomocí PostGISu je možné zpracovávat jak vektorová,
tak rastrová data. Nad vektorovými daty lze dokonce vybudovat
topologii a dotazovat se na ni. Nejobvyklejším využitím je ovšem
práce s jednoduchými prvky, tzv. *simple features.*

Obecná doporučení
-----------------

Začneme několika obecnými doporučeními. Vesměs se jedná o samozřejmé
věci. Domníváme se nicméně, že stojí za to si je připomenout.

Indexujte
^^^^^^^^^

U mnoha věcí platí, že než je dělat špatně, je lepší nedělat je
vůbec. Na indexy se výše uvedené nevztahuje. I špatný index je obvykle
lepší, než nic. Pokud nebudete používat indexy, je skoro jedno, jestli
budete ukládat data do databáze, nebo jen tak, do textových
souborů. Index si můžeme představit jako rejstřík u knihy, pokud kniha
nemá rejstřík, jediný způsob, jak najít nějakou informaci, je pročítat
knihu, dokud požadované údaje nenajdeme.  U PostgreSQL navíc (až na
výjimky) platí, že musí načíst z datové stránky celý záznam, aby se
dobralo hodnoty konkrétní položky.

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

Vzájemná izolace transakcí při současném zápisu je realizovaná
prostřednictvím `multigenerační architektury <http://postgres.cz/wiki/Slovník#MVCC>`_.

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
mezi správně nastavenou databází a defaultním nastavením klidně může
být o několik řádů. PostgreSQL se nastavuje jednak s ohledem na
hardware a jednak i s ohledem na požadované využití (předpokládaný
počet paralelně připojených uživatelů, velikost tabulek
atd.). Nastavení se provádí ručně a je netriviální. Pokud uděláte
zásadní chybu, hrozí havárie a to včetně rizika poškození dat. Pokud
se na to necítíte nebo nevíte přesně co děláte, je rozumné nechat si
poradit.

Základní úvod do problematiky je možné nabýt třeba `zde
<http://www.linuxexpres.cz/praxe/optimalizace-postgresql>`_ .

Naučte se používat psql
^^^^^^^^^^^^^^^^^^^^^^^

Psql je konzolový klient pro PostgreSQL, přestože působí poněkud
spartánsky, jedná se o nástroj se kterým je možné dosáhnout největší
efektivity. Specialitou jsou metacommandy. Použití psql v bashi je
velice mocná kombinace.

Kdy je výhodnější použít jiný nástroj
-------------------------------------

Je třeba si uvědomit, že PostGIS není analytický nástroj, ale
rozšíření databáze. Přestože v něm jde vyřešit drtivá většina úloh, se
kterými se můžeme ve své praxi setkávat, ne vždy se jedná o řešení
nejjednodušší, nejelegantnější a nejsprávnější. Vzhledem k tomu, že
PostGIS samotný pracuje se `Simple Features
<http://www.opengeospatial.org/standards/sfa>`_, tj. jednoduchými
geoprvky (ačkoliv existuje i rozšíření Topology), je využití PostGISu
pro analytické úlohy do jisté míry limitováno možnostmi jednoduchých
prvků. Dost velká omezení přináší také práce s velkými (co do množství
lomových bodů) prvky nebo prvky hodně členitými.
