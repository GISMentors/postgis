Obsah
=====

Vstupní znalost:
----------------
* Uživatel zná alespoň základy SQL
* Zvládne i počítač, na kterém nejsou windows

Výstupní dovednost:
-------------------
* Uživatel zvládne dostat data do postgis
* Uživatel zvládne dostat data z postgis ven
* Uživatel tuší, co má hledat, když chce data nějakým způsobem vizualizovat
* Uživatel má povědomí s čím rámcově musí počítat, když chce dotazovat větší data (dejme tomu RUIAN pro phu na slabším stroji)
* Uživatel tuší jak postupovat, když chce dostat z dat v postgisu informaci související s umístěním
* Uživatel zvládá samostatně řešit jednoduché analýzy v postgis

Potřebnosti:
------------
* Buď mašina s linuxem, postgre, qgisem a připojení na internet, nezaškodí pgadmin, libreoffice, rko
* Nebo přístupy na server přes ssh, na servru běží postgre, na klientu by se hodilo psql a data stačí prohlížet přes webovou prohglížečku (webový qgis)


Úkoly
-----
společně
    - připojit se v konzoli, nainstalovat postgis, doplnit 5514, vytvořit pracovní schémata

Každý na svém, zároveň s demonstrací
    - Načíst tabulku s xy body v křovákovi, vytvořit geometrii, nastavit srid a zobrazit
    - Načíst shp přes shp2pgsql (nastavit kódování, spravit souřadný systém)
    - Najít a pochopit chyby v topologii jednotlivých prvků, vysvětlit čemu to vadí a jak podobné věci řešit
    - Nahrát ruian pomocí GDAL, doplnit číselníky, porýpat se ve struktuře
    - Dotaz do ruian bez indexů a s indexy (součty ploch drupoz parcely pod 100 m bafrem z úlohy 1) 
    - Doplnit prostorové i jiné indexy
    - Nahrát očíslované body tras a vytvořit z nich linie
    - Nahrát data z mdb (když budou na servru mdb tools), udělat linie, zaplochovat pomocí topology a propojit s body z úlohy 1

Samostatně
    - Provést součty pod trasami z úkolu 7 (podle r_zpochr) výsledek zobrazit v mapě a v grafu
    - Namigrujte data z db dibavod. Vygenerujte padesát náhodných bodů po česku a ke každému zjistěte vzdálenost k nejbližšímu vodnímu toku a k nejbližší vodní ploše.
    - Vytvořit síť čtverců 5*5 kilometrů po celé republice. Vybrat deset náhodných. Pro náhodné čtverce najít a stáhnout správná data z ruian a vytvořit přehled druhů pozemků v průniku s každým čtvercem. Provést kontrolu, zda souhlasí sumy.
    - Analýza z připravených (nenamigrovaných) datasetů - tady musim vymyslet něco zábavnýho (jak se datař rozhoduje, kam pojede na dovolenou, dalekjo od mokřin, aby tam komáři neštípali, při cestě k babičce...)
