Prostorové funkce
=================

Z mnoha funkcí a funkcionalit nabízených PostGISem se zaměříme jen
na vybrané a to `analytické funkce
<http://postgis.net/docs/reference.html#Spatial_Relationships_Measurements>`_
a `funkce pro zpracování geometrií
<http://postgis.net/docs/reference.html#Geometry_Processing>`_.

Výpočet plochy, obvodu, délky a dalších charakteristik geometrie
----------------------------------------------------------------

Asi nejzákladnější informace, kterou můžeme o plošném prvku (polygonu)
zjistit je její výměru. Kromě typického zadání "zjisti, jak velkou
mají Vomáčkovi zahrádku" je nezbytná pro provedení pokročilejších úloh
typu "vyber obce, jejichž rozloha leží alespoň z osmdesáti procent v
národním parku atp".

.. tip:: Poměr výměry a obvodu polygonu se používá při odstraňování
	 "sliverů" (mezer mezi polygony).

Jedná se o následující funkce:

:pgiscmd:`ST_Length`
	 Délka linie lomené čáry

:pgiscmd:`ST_Area`
	 Výpočet výměry polygonu

:pgiscmd:`ST_Perimeter`
	 Vrací obvod polygonu

:pgiscmd:`ST_Centroid`
	 Vrací centroid polygonu

:pgiscmd:`ST_PointOnSurface`
	 Bod ležící uvnitř geometrie

Informace o vzájemném prostorovém vztahu prvků
----------------------------------------------

PostGIS definuje funkce pro určení prostorového vztahu prvků dle OGC
standardu `Simple Features
<http://www.opengeospatial.org/standards/sfa>`_ a to:

ST_Intesects a další
^^^^^^^^^^^^^^^^^^^^

:pgiscmd:`ST_Intersects`

	 Prvky sdílejí alespoň jeden bod, dochází k jejich prostorovému průniku.

.. code-block:: sql

   SELECT ST_Intersects('POLYGON((0 0,4 0,4 3,0 0))', 'POLYGON((2 0,6 0,6 3,2 0))');
   SELECT ST_Intersects('POLYGON((0 0,4 0,4 3,0 0))', 'POLYGON((4 0,8 0,8 3,4 0))');
   SELECT ST_Intersects('POLYGON((0 0,4 0,4 3,0 0))', 'POLYGON((5 0,9 0,9 3,5 0))');

:pgiscmd:`ST_Disjoint`

	 Doplněk k funkci :pgiscmd:`ST_Intersects`, prvky jsou prostorově různé.
              
:pgiscmd:`ST_Contains`

	 Prvek A prostorově obsahuje prvek B, tj. žádný bod z
	 geometrie B neleží vně geometrie A a alespoň jeden bod z B
	 leží uvnitř A.
              
:pgiscmd:`ST_Covers`

         Podobné jako :pgiscmd:`ST_Contains`

:pgiscmd:`ST_CoveredBy`

         Opačné pořadí argumentů, než u předešlých funkcí.

:pgiscmd:`ST_Within`

	 Doplněk k funkci :pgiscmd:`ST_Contains`, žádný bod z
	 geometrie A neleží vně geometrie B a alespoň jeden bod z A
	 leží uvnitř B.

:pgiscmd:`ST_DWithin`

         Podobná jako funkce :pgiscmd:`ST_Within`, geometrie leží v zadané
         vzdálenosti od jiné geometrie.

.. code-block:: sql

   SELECT ST_Within('POLYGON((0 0,4 0,4 3,0 0))'::geometry, 'POLYGON((0 0,8 0,8 6,0 0))'::geometry);
   SELECT ST_Contains('POLYGON((0 0,4 0,4 3,0 0))'::geometry, 'POLYGON((0 0,8 0,8 6,0 0))'::geometry);
   SELECT ST_Covers('POLYGON((0 0,4 0,4 3,0 0))'::geometry, 'POLYGON((0 0,8 0,8 6,0 0))'::geometry);
   SELECT ST_Contains('POLYGON((0 0,8 0,8 6,0 0))'::geometry, 'POLYGON((0 0,4 0,4 6,0 0))'::geometry);
   SELECT ST_Covers('POLYGON((0 0,8 0,8 6,0 0))'::geometry, 'POLYGON((0 0,4 0,4 6,0 0))'::geometry);
   SELECT ST_CoveredBy('POLYGON((0 0,4 0,4 3,0 0))'::geometry, 'POLYGON((0 0,8 0,8 6,0 0))'::geometry);
   SELECT ST_Covers( 'POLYGON((0 0,8 0,8 8,0 8,0 0))'::geometry,'POLYGON((1 1,5 1,5 4,1 1))'::geometry);

.. important:: Tyto funkce jsou často velmi podobné a liší se v
	       `detailech
	       <http://lin-ear-th-inking.blogspot.cz/2007/06/subtleties-of-ogc-covers-spatial.html>`_
	       (které však mohou být podstatné). 

:pgiscmd:`ST_Overlaps` 

	 Obdoba :pgiscmd:`ST_Intersects`, vrací true pouze tehdy,
	 pokud průnik je stejného typu jako vstupní prvky (tedy,
	 průnikem ploch je plocha, průnikem linií linie a tak dále) a
	 zároveň ani jeden prvek zcela nezakrývá druhý.

:pgiscmd:`ST_Crosses`

	 Prvky se prostorově kříží, tj. mají společný bod, ne však
         všechny.

:pgiscmd:`ST_Touches`

	 Prvky se prostorově dotýkají, tj. mají společný bod, ne však
	 společný vnitřek.

:pgiscmd:`ST_Equals`

	 Geometrická shoda prvků.

ST_Relate
^^^^^^^^^

:pgiscmd:`ST_Relate`

      Obecné určení vzájemného prostorového vztahu prkvů vychází z takzvané
      "matice devíti průniků" (DE-9IM), viz `manuál
      <http://postgis.net/docs/using_postgis_dbmanagement.html#DE-9IM>`_. Bližší
      informace o této problematice `zde
      <http://geo.fsv.cvut.cz/~gin/uzpd/uzpd.pdf#41>`_.

      Matice průniků vypadá následovně:

      .. table::
         :class: border
                 
         +-------------------+-------------------+---------------+-------------------+
         |    **A/B**        | **vnitřní část**  |  **hranice**  |  **vnější část**  |
         +-------------------+-------------------+---------------+-------------------+
         | **vnitřní část**  |                   |               |                   |
         +-------------------+-------------------+---------------+-------------------+
         | **hranice**       |                   |               |                   |
         +-------------------+-------------------+---------------+-------------------+
         | **vnější část**   |                   |               |                   |
         +-------------------+-------------------+---------------+-------------------+

      V každém políčku se objeví požadovaná dimenze prvku, který vznikne
      průnikem prvků A a B. Tedy pro bod :option:`0`, linii :option:`1` a
      polygon :option:`2`. Další povolené hodnody jsou :option:`F` pro
      prázdný průnik, :option:`T` pro libovolný neprázdný průnik a
      :option:`*` v případě, že informaci o průniku na tomto místě matice
      nepovažujeme za směrodatnou.

      Tuto funkcionalitu v PostGISu zajištuje funkce :pgiscmd:`ST_Relate`.
      Funkci můžeme použít ve dvou tvarech. Pokud zadáme jako třetí argument
      matici průniku (i s využitím "divokých karet"), tak funkce vrací
      hodnoty true/false podle toho, zda jsou všechny podmínky v matici
      splněny. Případně funkci můžeme použít jen se dvěma argumenty,
      geometriemi. Potom funkce vrací matici průniku, případně můžeme přidat
      argument pro číslo pro pravidlo uzlů hranice.

      .. code-block:: sql

         -- výpis matice průniku
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

         -- mají dva polygony společný prostor?
         SELECT ST_Relate('POLYGON((1 1,1 4,4 4,4 1,1 1))'::geometry, 
            'POLYGON((0 0,0 3,3 3,3 0,0 0))'::geometry, '2********');

         --dva polygony se vzájemně nepřekrývají
         SELECT ST_Relate('POLYGON((1 1,1 4,4 4,4 1,1 1))'::geometry, 
            'POLYGON((0 0,0 3,3 3,3 0,0 0))'::geometry, 'F********');

         -- polygony se nepřekrývají a nemají ani společnou hranici
         SELECT ST_Relate('POLYGON((1 1,1 4,4 4,4 1,1 1))'::geometry, 
            'POLYGON((5 5,9 5,9 9,5 9,5 5))'::geometry, 'F***F****');

ST_Distance
^^^^^^^^^^^

:pgiscmd:`ST_Distance` vrací minimální vzdálenost mezi dvěma prvky.

.. important:: U funkcí, které pracují s prostorovými vztahy je třeba brát v
               potaz zda použitá funkce pracuje interně s MOO a indexy.
               Například funkce :pgiscmd:`ST_Intersects` s nimi pracuje a funkce
               :pgiscmd:`ST_Relate` nikoliv. V případě, že funkce nepoužívá
               index je vhodné ji optimalizovat použitím poddotazu s operátorem.

               Pokud chcete použít funkci bez předchozího použití operátoru,
               přidejte před název funkce podtržítko. (_ST_DWithin místo
               ST_DWithin)

               .. tip:: Podívejte se na zdrojové kódy variant funkce ST_DWithin,
                  najdete je v tabulce pg_proc.

Geometrické analýzy
-------------------

V této části se zaměříme na funkce, které vrací modifikovanou
geometrii vstupních prvků.

:pgiscmd:`ST_Buffer`

      Obalová zóna. Funkce má dva parametry: vstupní geometrii a
      šířka zóny. Je možné zadat ještě nějaké další parametry
      (počet segmentů na čtvrtinu kruhu, "čepičky", "kolínka" atp).

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

            -- počet segmentů 100
            SELECT COUNT(NULLIF(ST_Intersects(adresnibod, ST_Buffer(geom_p, 250, 100)), false)) 
            FROM 
            (
               SELECT geom_p, adresnibod FROM adresy a, vesmirne_zrudice v 
               WHERE v.id = 1 
               AND a.adresnibod && ST_Buffer(v.geom_p, 250, 100)
            ) data;

:pgiscmd:`ST_Expand`

         Vrací MOO prvku zvětšený na každou stranu o zadaný rozměr. Je možné
         zadat jednu hodnotu, nebo hodnoty dvě, jednu pro osu x a druhou pro osu
         y.

         .. tip:: Srovnejte rychlost dotazu s použitím operátoru && při použití
                  ST_Buffer a ST_Expand.

:pgiscmd:`ST_Difference`

	 Vrací prostorový rozdíl prvků.

:pgiscmd:`ST_Intersection`

	 Vrací prostorový průnik prvků.

:pgiscmd:`ST_Union`
	 
	 Vrací prostorové sjednocení prvků.

:pgiscmd:`ST_Split`

	 Rozdělí prvek podle jiného prvku a vrátí typ *geometry
         collection*. Možné použít například pro dělení prvků na
         základě mřížky.

Agregační funkce
----------------

Sloučí geometrii z více záznamů do jednoho.

:pgiscmd:`ST_Collect`, :pgiscmd:`ST_UnaryUnion`, :pgiscmd:`ST_Union`

         Různé typy sjednocení.

:pgiscmd:`ST_MakeLine`

         Vytvoří linii z množiny bodů.

Další funkce
------------

Výběr z oblíbených funkcí.

ST_IsValid a ST_MakeValid
^^^^^^^^^^^^^^^^^^^^^^^^^

:pgiscmd:`ST_IsValid`, :pgiscmd:`ST_IsValidDetail`, případně
:pgiscmd:`ST_IsValidReason`

   Slouží ke zjištění, zda je prvek geometricky validní.

:pgiscmd:`ST_MakeValid`

   Nahradí invalidní geometrii validní geometrií, zkrátka prvek zvaliduje.

ST_Multi
^^^^^^^^

:pgiscmd:`ST_Multi`

   Mění typ geometrie z jednoduché na *multigeometrii*.

.. code-block:: sql

   SELECT ST_AsText(ST_Multi('LINESTRING(1 1,5 5)'::geometry));


ST_Dump
^^^^^^^

:pgiscmd:`ST_Dump`

   Rozpustí "multi" geometrii, nebo
   *GEOMETRYCOLLECTION* na jednotlivé komponenty.  Vrací typ record s
   geometrií a cestou ke geometrii v *GEOMETRYCOLLECTION*.

ST_CollectionExtract
^^^^^^^^^^^^^^^^^^^^

:pgiscmd:`ST_CollectionExtract`

   Vyfiltruje z *GEOMETRYCOLLECTION* bodové, liniové, nebo plošné prvky.
