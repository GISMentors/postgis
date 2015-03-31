Prostorové funkce
=================

Z celé přehršle funkcí a funkcionalit nabízených PostGISem vyberem jen
některé. Zaměříme se na vybrané `analytické funkce
<http://postgis.net/docs/manual-2.1/reference.html#Spatial_Relationships_Measurements>`_
a `funkce na processing geometrií
<http://postgis.net/docs/manual-2.1/reference.html#Geometry_Processing>`_.

Výpočet plochy, obvodu, délky a dalších charakteristik geometrie
----------------------------------------------------------------

Asi nejzákladnější informace, kterou můžeme o ploše zjistit je její
rozloha. Kromě základního zadání "zjisti, jak velkou mají Vomáčkovi
zahrádku" je nezbytná pro provedení pokročilejších úloh typu "vyber
obce, jejichž rozloha leží alespoň z osmdesáti procent v národním
parku atp". Poměr plochy a obvodu se používá při odstraňování
"sliverů".

Jedná se například o funkce:

:ST_Area: Výpočet plochy

:ST_Length: Délka linie

:ST_Centroid: Vrací centroid 

:ST_PointOnSurface: Bod ležící uvnitř geometrie

:ST_Perimeter: Vrací obvod

Informace o vzájemné poloze prvků
---------------------------------

Celá řada funkcí nám vrací nějakou informaci o `vzájemné poloze dvou
geometrií
<http://postgis.net/docs/manual-2.1/using_postgis_dbmanagement.html#DE-9IM>`_.

ST_Relate
^^^^^^^^^

Je jakousi nejobecnější rovinou, v jaké lze s informací o vzájemné
poloze dvou prvků něco zjistit. Pracujeme zde s takzvanou "maticí
devíti průniků".

.. table::
   :class: border
           
   +-----------+------------+------------+------------+
   |    A/B    |  interior  |  boundary  |  exterior  |
   +-----------+------------+------------+------------+
   | interior  |            |            |            |
   +-----------+------------+------------+------------+
   | hranice   |            |            |            |
   +-----------+------------+------------+------------+
   | exterior  |            |            |            |
   +-----------+------------+------------+------------+

V každém políčku je vyplněn počet rozměrů průniku. Tedy pro bod je
:option:`0`, pro linii :option:`1` a pro polygony :option:`2` Může být
také vyplněno :option:`F` pro prázdný průnik, :option:`T` pro
libovolný neprázdný průnik a :option:`*` použijeme v případě, že
informaci o průniku na tomto místě matice nepovažujeme za směrodatnou.

Funkci můžeme použít ve dvou tvarech, můžeme zadat jako třetí argument
matici (i s využitím "divokých karet"), pak vrací funkce true/false
Případně funkci můžeme použít jen se dvěma argumenty, geometriemi, pak
fce vrací matici, případně můžeme přidat argument pro číslo pro
pravidlo uzlů hranice.

.. code-block:: sql

   SELECT ST_Relate('POLYGON((1 1,1 3,3 3,3 1,1 1))'::geometry, 
      'POLYGON((1 1,1 3,3 3,3 1,1 1))'::geometry);
   SELECT ST_Relate('POLYGON((1 1,1 3,3 3,3 1,1 1))'::geometry, 
      'POLYGON((0 0,0 3,3 3,3 0,0 0))'::geometry);
   SELECT ST_Relate('POLYGON((1 1,1 4,4 4,4 1,1 1))'::geometry, 
      'POLYGON((0 0,0 3,3 3,3 0,0 0))'::geometry);
   SELECT ST_Relate('POLYGON((3 3,3 4,4 4,4 3,3 3))'::geometry, 
      'POLYGON((0 0,0 3,3 3,3 0,0 0))'::geometry);
   SELECT ST_Relate('POLYGON((0 3,0 6,3 6,3 3,0 3))'::geometry, 
      'POLYGON((0 0,0 3,3 3,3 0,0 0))'::geometry);
   ---
   --mají dva polygony společný prostor

   SELECT ST_Relate('POLYGON((1 1,1 4,4 4,4 1,1 1))'::geometry, 
      'POLYGON((0 0,0 3,3 3,3 0,0 0))'::geometry, '2********');
   --dva polygony se vzájemně nepřekrývají
   SELECT ST_Relate('POLYGON((1 1,1 4,4 4,4 1,1 1))'::geometry, 
      'POLYGON((0 0,0 3,3 3,3 0,0 0))'::geometry, 'F********');
   --nepřekrývají a nemají společnou hranici
   SELECT ST_Relate('POLYGON((1 1,1 4,4 4,4 1,1 1))'::geometry, 
      'POLYGON((5 5,9 5,9 9,5 9,5 5))'::geometry, 'F***F****');

ST_Intersects, ST_Overlaps, ST_Touches a další
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Na podobném principu jako předešlá funkce pracuje řada dalších funkcí,
které vrací true/false podle toho, zda jsou prostorové prvky ve
správné poloze.

:ST_Intersects: True za předpokladu, že prvky sdílejí alespoň jeden bod.

.. code-block:: sql

   SELECT ST_Intersects('POLYGON((0 0,4 0,4 3,0 0))', 'POLYGON((2 0,6 0,6 3,2 0))');
   SELECT ST_Intersects('POLYGON((0 0,4 0,4 3,0 0))', 'POLYGON((4 0,8 0,8 3,4 0))');
   SELECT ST_Intersects('POLYGON((0 0,4 0,4 3,0 0))', 'POLYGON((5 0,9 0,9 3,5 0))');

:ST_Disjoint: NOT ST_Intersects
              
:ST_Contains: Obsahuje, tedy žádný bod z geometrie B neleží vně geometrie A a alespoň jeden bod z B leží uvnitř A.
              
:ST_Covers: Podobné jako ST_Contains

:ST_CoveredBy: Opačné pořadí argumentů, než u předešlých funkcí.

:ST_Within: Podobné jako ST_CoveredBy

.. code-block:: sql

   SELECT ST_Within('POLYGON((0 0,4 0,4 3,0 0))'::geometry, 'POLYGON((0 0,8 0,8 6,0 0))'::geometry);
   SELECT ST_Contains('POLYGON((0 0,4 0,4 3,0 0))'::geometry, 'POLYGON((0 0,8 0,8 6,0 0))'::geometry);
   SELECT ST_Covers('POLYGON((0 0,4 0,4 3,0 0))'::geometry, 'POLYGON((0 0,8 0,8 6,0 0))'::geometry);
   SELECT ST_Contains('POLYGON((0 0,8 0,8 6,0 0))'::geometry, 'POLYGON((0 0,4 0,4 6,0 0))'::geometry);
   SELECT ST_Covers('POLYGON((0 0,8 0,8 6,0 0))'::geometry, 'POLYGON((0 0,4 0,4 6,0 0))'::geometry);
   SELECT ST_CoveredBy('POLYGON((0 0,4 0,4 3,0 0))'::geometry, 'POLYGON((0 0,8 0,8 6,0 0))'::geometry);
   SELECT ST_Covers( 'POLYGON((0 0,8 0,8 8,0 8,0 0))'::geometry,'POLYGON((1 1,5 1,5 4,1 1))'::geometry);

.. warning:: I když se tyto funkce tváří podobně, jsou mezi nimi `rozdíly <http://lin-ear-th-inking.blogspot.cz/2007/06/subtleties-of-ogc-covers-spatial.html>`_

:ST_Overlaps: Je podobná ST_Intersects, ovšem vrací true pouze tehdy,
              pokud průnik je stejného typu jako vstupní plochy (tedy,
              průnikem ploch je plocha, průnikem linií linie a tak
              dále) a zároveň ani jeden prvek zcela nezakrývá druhý.

:ST_Crosses: Pokud mají obě geometrie nějaký společný bod, ne však
             všechny.

:ST_Touches: Pokud mají společný bod, ne však společný vnitřek.

:ST_Equals: Geometrická shoda.

.. important:: Tyto funkce jsou často velmi podobné a liší se v
               detailech (které však mohou být podstatné). Mohou to
               být také implementace různých standardů, mohou mít
               odlišné požadavky na výkon.

ST_Distance
^^^^^^^^^^^

Funkce ST_Distance vrací, celkem nepřekvapivě minimální vzdálenost
mezi dvěma prostorovými prvky.


Geometrické analýzy
-------------------

Celá řada funkcí vrací změněnou geometrii, představíme si několik z
nich.

:ST_Buffer: Obalová zóna, tři parametry, vstupní geometrie, šířka zóny
            a počet segmentů na čtvrtinu kruhu. Je možné zadat ještě
            nějaké další parametry ("čepičky", "kolínka" atp).

.. warning:: Různý počet segmentů se může projevit i v počtu vybraných
             bodů.

.. code-block:: sql

   SET SEARCH_PATH = ukol_1, public;

   SELECT COUNT(NULLIF(ST_Intersects(adresnibod, ST_Buffer(geom_p, 250)), false)) 
   FROM 
   (
      SELECT geom_p, adresnibod FROM adresy a, vesmirne_zrudice v 
      WHERE v.id = 1 
      AND a.adresnibod && ST_Buffer(v.geom_p, 250)
   ) data;

   SELECT COUNT(NULLIF(ST_Intersects(adresnibod, ST_Buffer(geom_p, 250, 100)), false)) 
   FROM 
   (
      SELECT geom_p, adresnibod FROM adresy a, vesmirne_zrudice v 
      WHERE v.id = 1 
      AND a.adresnibod && ST_Buffer(v.geom_p, 250, 100)
   ) data
   ;


:ST_Difference: Prostorový rozdíl

:ST_Intersection: Průnik.

:ST_Split: Rozdělí prvek podle jiného prvku a vrátí geometry
           collection. Možné použít například pro dělení prvků podle
           sítě.

:ST_Union: Spojí dvě geometrie.

Agregační funkce
----------------

:ST_Union, ST_Dump, ST_Collect, ST_UnaryUnion: Různé typy sjednocení.

:ST_MakeLine: Vytvoří linii z množiny bodů.

Speciální Funkce
----------------

ST_IsValid a ST_MakeValid
^^^^^^^^^^^^^^^^^^^^^^^^^

ST_IsValid, případně ST_IsValidDetail, nebo ST_IsValidReason slouží ke
zjištění, zda je prvek geometricky validní.

ST_MakeValid nahradí invalidní geometrii validní geometrií, zkrátka
prvek zvaliduje.

ST_Multi
^^^^^^^^

Mění typ geometrie z jednoduché na *Multi*.

.. code-block:: sql

   SELECT ST_AsText(ST_Multi('LINESTRING(1 1,5 5)'::geometry));
