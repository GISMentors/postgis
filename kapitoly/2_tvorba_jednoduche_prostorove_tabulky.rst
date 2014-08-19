Vytváříme prostorovou tabulku
=============================

*Záhadná vesmírná obludnost ukryla po praze svoje zrůdná vejce. Podařilo se, s nasazením života, získat jejich souřadnice. Nyní musíme vytvořit v postgisu tabulku, ze které si je budou moci zobrazit teréní agenti, aby vejce našli a zneškodnili, dřív, než se z nich vylíhnou malé, nepředstavitelně ohavné, obludky.*

Jak dostat data do Postgre
--------------------------

Dejme tomu, že naše data budou vypadat nějak takto:
::

   1	-750922.065478723	-1042251.84362287
   2	-740606.682644681	-1050443.47116755
   3	-734083.719970213	-1041569.20799415
   4	-748191.52296383	-1055449.46577819
   5	-739810.27441117	-1038080.18144734
   ...

S tím, že známe strukturu, která vypadá takto:
::

   id	x	y

Oddělovač je tabelátor.

Dostat takovouto jednoduchou tabulku do Postgre můžeme celou řadou způsobů. Můžeme pomocí `sed` převést jednotlivé řádky na insert statementy. Můžeme použít libre/open office jak je popsáno `zde <http://grasswiki.osgeo.org/wiki/Openoffice.org_with_SQL_Databases#Converting_Excel.2C_CSV.2C_..._to_PostgreSQL.2FMySQL.2F..._via_OO-Base>`_ (to je, mimochodem, velice užitečná technika, pokud někdy budete potřebovat do Postgre převést větší množství dat z excelu, jako jsou číselníky z ČUZK, data se statistického úřadu apod). Můžeme tabulku otevřít v qgisu a ze souřadnic rovnou udělat geometrii, uložit do shp a použít `shp2pgsql`. To se hodí obzvlášť pokud dostanete od někoho data opsané ručně z GPS navigace v minutách a vteřinách. Qgis umí načíst tato data rovnou a ušetříte si poměrně otravné přepočítávání. Nicméně nejpřímější cesta jak dostat textovou tabulku do postgre je použití **COPY**.

Manuál k COPY je `tady <http://www.postgresql.org/docs/9.4/static/sql-copy.html>`_.

Copy je příkaz na kopírování dat mezi databázovou tabulku a textovým souborem. A to v obou směrech. Kopírovate můžeme ze/do souboru, z výstupu skriptu a ze standartního vstupu/na standartní výstup. Je možné nastavovat přehršel možností, oddělovače polí, řádků, hodnoty NULL, přítomnost řádku s hlavičkou, kódování a další. V případě, že máme nějaká data v exotickém formátování, vyplatí se vyzkoušet, jestli se nám nepodaří je do copy nakrmit, než je začneme soukat přez nějaké skripty na přeformátování. 

Příklad kreativního využití `copy` pro přenos dat mezi dvěma servery:
::

   psql -h prvni_server.cz -c "COPY a TO STDOUT" db1 | psql -h druhy_server.cz -c "COPY b (a, b, c) FROM STDIN" db2

.. note:: Od verze 9.4 umí postgre jednu velice šikovnou věc a to *COPY FROM PROGRAM*, pomocí kterého nekopírujete ze souboru, ale z puštěného skriptu. Velice praktické například při pravidelném skenování stránek s nějakými uspořádanými daty. `Příklad použití <http://www.cybertec.at/importing-stock-market-data-into-postgresql/>`_. Je však třeba vzít potaz, že skript je spouštěn pod uživatelem, pod kterým běží databázový server a je nutné, aby tomu odpovídalo nastavení práv.

Nás ovšem bude zajímat kopírování ze souboru do tabulky. Copy, totiž, jakkoliv je skvělé, má jedno omezení. Kopíruje totiž soubor, který leží na databázovém serveru a jako uživatel pod kterým je puštěné postgre (obvykle postgres) a někdy může být problematické soubor na server dostat a patřičná oprávnění mu přidělit. Řeší se to několika triky.

Dump formát
^^^^^^^^^^^

Upravíme data do podoby v jaké bývají produkována z pg_dump:
::

   COPY vesmirne_zrudice (id, x, y) FROM stdin;
   1	-750922.065478723	-1042251.84362287
   2	-740606.682644681	-1050443.47116755
   3	-734083.719970213	-1041569.20799415
   4	-748191.52296383	-1055449.46577819
   5	-739810.27441117	-1038080.18144734
   \.

Jak patrno, stačí doplnit první řádek s COPY a poslední s označením konce vkládání. Výsledný skript pustíme pomocí psql -f. 

Tento postup je výhodný, pokud píšeme nějaké skripty pro převody dat, když doplníme dva jednoduché řádky, můžeme snadno posílat výstup ze skriptu rovnou na psql, aniž by bylo třeba ho někam ukládat.

Roura
^^^^^

Další možnost je posílat data rourou:
::

   cat body.csv | psql -h server.cz -c "COPY body (id, x, y) FROM STDIN" db

Metacommand \copy
^^^^^^^^^^^^^^^^^

Poslední možností, kterou já osobně používám nejčastěji pro ruční nahrávání dat, která dostanu v textovém formátu. \copy funguje podobně jako COPY, ovšem s tím rozdílem, že kopírujete data z počítače na kterém je spuštěno psql a pod právy uživatele, který pustil psql. Když tedy chcete naplnit tabulky daty, které máte na svém lokále, je toto nejefektivnější postup. 

.. note:: \copy je metacommand psql, nikoliv SQL dotaz, funguje tedy jen v psql, není tedy možné s ním počítat v rámci přístupu k databázi z programovacích jazyků, různých grafických nástrojů apod.

Vytváříme tabulku
-----------------
