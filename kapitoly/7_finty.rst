===============
Efektivní práce
===============

Pohledy
=======

:pgsqlcmd:`Pohled <sql-createview>` v databázi je v podstatě dotaz, který se
tváří jako tabulka. Můžeme mu nastavit práva a dotazovat ho. Výhodou pohledů
je, že pracují s tabulkami se stejnými právy, jaká měl jejich tvůrce. Můžeme
tedy pomocí pohledů zpřístupnit uživateli obsah tabulek, které mu nechceme
ukázat celé.

Pohledy můžeme zobrazit v QGISu, pakliže obsahují grafickou složku. Můžeme si
tedy, připravit dotazy, které nás zajímají a pracovat s nimi, aniž bychom museli
výsledky analýz ukládat do nových tabulek.


.. code-block:: sql

   SET SEARCH_PATH TO ukol_1, public;

   CREATE OR REPLACE VIEW parcely_podle_gridu AS
   SELECT row_number() over() id1
   , p.*, grid.id grid_id
   FROM parcely p, jtsk_grid grid
   WHERE p.definicnibod && grid.geom;


.. figure:: ../images/parcely_dle_gridu.png

   Výsledek pohledu - obarvení parcel podle gridu.
   
Materializované pohledy
=======================

:pgsqlcmd:`Materializovaný pohled <sql-creatematerializedview>` je v mnoha
ohledech podobný jako pohled. Liší se jednou zásadní věcí, dotázaná data jsou
skutečně uložena, podobně, jako když vytvoříte tabulku z výsledku dotazu. Data
jsou tím pádem statická a nemění se při změně zdrojových dat. Na druhou stranu
takto uložená data jsou vrácena ihned, v případě složitého a výpočetně náročného
dotazu může být výsledek vrácen mnohonásobně rychleji.

Na rozdíl od prostého uložení výsledku dotazu do tabulky si materializovaný
pohled s sebou nese i původní dotaz ze kterého byl vytvořen. Je možné ho obnovit
příkatem :pgsqlcmd:`REFRESH MATERIALIZED VIEW <sql-refreshmaterializedview>`.

.. tip:: Materializovaný pohled lze indexovat, podobně jako tabulku.


.. important:: Při obnovení materializovaného pohledu musíte mít stejně
   nastavený search_path jako při jeho tvorbě. To s sebou může nést problémy
   například při obnově databáze ze zálohy vytvořené pomocí pg_dump.

UDF funkce
==========

Funkce UDF (User Defined Function) vytváříme příkazem :pgsqlcmd:`CREATE FUNCTION 
<sql-createfunction>`. Funkce může být napsaná přímo v jazyce `SQL`, v 
procedurálním jazyce PostgreSQL `PL/pgSQL`, případně v jakémkoliv jazyce,
který podporuje PostgreSQL.

Ukažme si jednoduchý příklad funkce, která vrací kolik procent polygonu
je zakryto druhým polygonem.

.. code-block:: sql

   CREATE OR REPLACE FUNCTION procento_prekryvu(geometry, geometry) 
   RETURNS float AS $fbody$
      SELECT
      (
         ST_Area(ST_Intersection($1, $2))/
         ST_Area($1)
      ) * 100;
   $fbody$
   LANGUAGE SQL;

   SELECT procento_prekryvu(
      ST_Buffer(ST_MakePoint(0,0), 50),
      ST_Buffer(ST_MakePoint(50,0), 25));

.. noteadvanced:: U funkcí v PostgreSQL funguje přetěžování proměnných, takže
   je možné napsat celou řadu funkcí pro různé kombinace proměnných.

Složitější funkci si ukážeme v Pl/pgSQL. Bude se jmenovat `šupiny` a bude vracet
polygon oříznutý o části, které jsou zakryté polygony v tabulce šupiny.

.. code-block:: sql


   BEGIN;

   CREATE TABLE supiny (
      id SERIAL PRIMARY KEY
      , geom geometry(POLYGON, 0)
   );

   CREATE OR REPLACE FUNCTION supiny(sup geometry) 
   RETURNS geometry AS $$
   DECLARE 
   odecist geometry;
   BEGIN
      odecist := ST_MemUnion(geom) FROM supiny
      --normální UNION zlobí kvůli topologickým chybám
      WHERE geom && sup;
      /* vyfiltruji prvky z okoli zajmoveho uzemi*/
      IF odecist IS NULL THEN --odecist je prazdny
         RETURN sup;
      ELSE
         RETURN 
            ST_CollectionExtract(ST_Difference(sup, odecist),3)
            ;
         /* Collection extract vybere pouze polygony*/
      END IF;

   END;
   $$ LANGUAGE plpgsql;

   --vygeneruji náhodná data

   DO $$
      DECLARE i int;
      BEGIN
         FOR i in 1..500 LOOP
            INSERT INTO supiny(geom)
            SELECT (ST_Dump(
                  supiny(
                     ST_Buffer(
                        ST_Point(
                           random() * 100
                           , random() * 100
                     ), (random() * 10) + 10
                     , 25
                  )
               )
            )).geom;
         END LOOP;
      END
      $$;



   COMMIT;


.. figure:: ../images/supiny.png
   :class: middle

   Výsledek volání funkce supiny.


Common table expression
=======================

:pgsqlcmd:`Common table expression <queries-with>` (CTE) má hned několik 
zajímavých vlastností. Tou první je možnost rekurze. To je možné využít
například při generování čtvercové sítě nebo generování hierarchických
struktur.

Použití rekruzivního :sqlcmd:`CTE` si předvedeme v následujícím příkladu.

	
.. code-block:: sql

   SET SEARCH_PATH TO ukol_1, public;

   CREATE TABLE jtsk_grid AS
   WITH RECURSIVE
   bb AS (
      SELECT ST_Extent(originalnihranice) bbgeom FROM budovy
   )
   , x AS (
      SELECT ST_XMin(bbgeom) a FROM bb
      UNION
      SELECT a + 1000 FROM x WHERE a < (SELECT ST_XMax(bbgeom) FROM bb)
   )
   , y AS (
      SELECT ST_YMin(bbgeom) a FROM bb
      UNION
      SELECT a + 1000 FROM y WHERE a < (SELECT ST_YMax(bbgeom) FROM bb)
   )
   SELECT 
   row_number() over() id
   , x.a x, y.a y
   , ST_SetSRID(
      ST_Envelope(
         ST_UNION(ST_MakePoint(x.a, y.a, 5514)
            , ST_MakePoint(x.a + 1000, y.a + 1000, 5514)
         )
      ), 5514
   )::geometry(POLYGON, 5514) geom FROM x, y;

.. noteadvanced:: Místo rekurzivního CTE lze v tomto příkladu použít
   *generate_series* s týmž výsledkem.

.. figure:: ../images/db_manager_cte.png
   :class: middle

   Dotaz můžeme pustit přímo z db manageru QGISu.
            
.. figure:: ../images/jtsk_grid.png

   Výsledek - vytvořený grid v S-JTSK.

Druhá ze zajímavých vlastností CTE je způsob, jakými jsou
optimalizovány. Každá CTE je totiž optimalizována zvlášť.
Toho se dá využít při optimalizaci dotazů.

CTE můžeme libovolně řetězit a navzájem dotazovat. To se dá dobře
použít, když budeme chtít postupně redukovat množinu dotazovaných
prvků pomocí stále přesnějších (a tím pádem výpočetně náročnějších)
dotazů. S pomocí CTE je možné dotáhnout pravidlo `výpočetně náročné
operace provádějte s nejmenším možným počtem prvků`.

Dejme tomu, že chceme zjistit výměru průniků budov s pozemky určenými
k plnění funkce lesa v Praze.

.. code-block:: sql

   SET SEARCH_PATH TO ukol_1, public;

   EXPLAIN ANALYZE
   WITH zpochr_26 AS ( --PUPFL
      SELECT *
      FROM parcely
      WHERE zpusobochranykod = 26
   )
   , bud AS ( --filtr na boundingbox
      SELECT *
      FROM budovy b
      WHERE EXISTS (
         SELECT 1 FROM zpochr_26 z
         WHERE z.originalnihranice && b.originalnihranice
      )
   ), prunik AS
   (
      SELECT ST_CollectionExtract(
            ST_Intersection(
            ST_UNION(z.originalnihranice)
            , ST_Union(b.originalnihranice)
         ), 3
      ) geom
      FROM bud b, zpochr_26 z
      WHERE b.originalnihranice && z.originalnihranice
      GROUP BY z.ogc_fid
   )

   SELECT sum(ST_Area(geom)) from prunik;

   -- srovnaní

   EXPLAIN ANALYZE
   SELECT sum(ST_Area(
         ST_Intersection(
            p.originalnihranice, b.originalnihranice
         )
      )
   )
   FROM parcely p, budovy b
   WHERE p.zpusobochranykod = 26
   AND ST_Intersects(p.originalnihranice, b.originalnihranice)

Tento příklad ukazuje, že ani pokročilé použití CTE nemusí být výhodnější
než použití jednoduchého dotazu. Je to proto, že se jedná o jednoduchý
dotaz, který optimalizátor může správně uchopit. U složitější situace
to může být naopak. Problematické je navíc použití klauzule :sqlcmd:`EXISTS`.


.. code-block:: sql

   SET SEARCH_PATH TO ukol_1, public;

   WITH zpochr_26 AS ( --PUPFL
      SELECT *
      FROM parcely
      WHERE zpusobochranykod = 26
   )
   , bud AS ( --filtr na boundingbox
      SELECT z.originalnihranice a, b.originalnihranice b
      FROM budovy b, zpochr_26 z
      WHERE z.originalnihranice && b.originalnihranice
   )

   SELECT ST_Area(ST_Union(ST_Intersection(a,b))) FROM bud;


Každopádně :pgiscmd:`ST_Intersects` umí využívat operátory a potažmo indexy,
takže v tomto konkrétním případě má stále navrch.

.. code-block:: sql

   SET SEARCH_PATH TO ukol_1, public;

   EXPLAIN ANALYZE
   SELECT sum(ST_Area(
         ST_Intersection(
            p.originalnihranice, b.originalnihranice
         )
      )
   )
   FROM parcely p, budovy b
   WHERE p.zpusobochranykod = 26
   AND ST_Relate(p.originalnihranice, b.originalnihranice, '2********')



Anonymní blok kódu
==================

:pgsqlcmd:`Anonymní blok kódu <sql-do>` umožňuje spouštět dávku v PL/pgSQL mimo
funkce.

Ukázka z příkladu výše ukazuje, jak pustit ve smyčce vytvoření pěti set náhodných
bublin.

.. code-block:: sql

   DO $$
      DECLARE i int;
      BEGIN
         FOR i in 1..500 LOOP
            INSERT INTO supiny(geom)
            SELECT (ST_Dump(
                  supiny(
                     ST_Buffer(
                        ST_Point(
                           random() * 100
                           , random() * 100
                     ), (random() * 10) + 10
                     , 25
                  )
               )
            )).geom;
         END LOOP;
      END
      $$;

Využít se dá s výhodou, když provádíme průnik prvků dvou obsáhlejších tabulek.


.. code-block:: sql

   SET SEARCH_PATH TO ukol_1, public;

   BEGIN;

   CREATE TABLE prunik (
      ogc_fid int, 
      geom geometry(POLYGON, 5514)
   );

   DO $$
      DECLARE r prunik; --record podle tabulky prunik
      g geometry;
      r2 record;

      BEGIN
         FOR r IN SELECT ogc_fid, (ST_Dump(originalnihranice)).geom geom 
            FROM budovy 
            WHERE ST_IsValid(originalnihranice)
            LOOP
            RAISE NOTICE 'zpracovávám ogc_fid %', r.ogc_fid;
            g := ST_Multi(
               ST_CollectionExtract(
                  ST_Intersection(
                     r.geom, ST_Union(ST_MakeValid(originalnihranice))
                  ), 3
               )
            )
            FROM parcely
            WHERE originalnihranice && r.geom;

            FOR r2 IN SELECT (ST_Dump(g)).geom LOOP

               IF ST_GeometryType(r2.geom) = 'ST_Polygon' THEN
                  r.geom := r2.geom;
                  INSERT INTO prunik VALUES(r.*);
               END IF;

            END LOOP;



         END LOOP;
      END
      $$;

      SELECT count(*) FROM prunik;

   ROLLBACK;

LATERAL
=======

Použití LATERAL je poměrně oblíbené mezi uživateli PostGIS. Může být použito v
klauzuli :sqlcmd:`FROM`, nebo :sqlcmd:`JOIN`. Relace (může se jednat o tabulku,
pohled, materializovaný pohled, případně funkci vracející recordset, jako třeba
:sqlcmd:`ST_Dump`) se dotazuje zvlášť pro každý záznam hlavní tabulky. Obzvláště
výhodné je její použití s LIMIT u výpočetně náročných podmínek.

Například pokud chceme najít všechny katastry, na kterých je alespoň jedno
maloplošné chráněné území. Chceme se vyvarovat toho, aby bylo vybráno
katastrální území, na kterém je více než jedno katastrální území vícekrát neý
jednou.

Použijeme tabulku :dbtable:`ruian.katastralniuzemi` a tabulku
:dbtable:`ochrana_uzemi.maloplosna_uzemi`.

Klasické je použití klauzule :sqlcmd:`EXIST`

.. code-block:: sql

   EXPLAIN ANALYZE
   SELECT *
   FROM ruian.katastralniuzemi
   WHERE EXISTS (
      SELECT True
      FROM ochrana_uzemi.maloplosna_uzemi
      WHERE ST_Intersects(maloplosna_uzemi.geom, katastralniuzemi.geom)
   );

S využitím :sqlcmd:`LATERAL`

.. code-block:: sql

   EXPLAIN ANALYZE
   SELECT *
   FROM ruian.katastralniuzemi
   , LATERAL (
      SELECT True
      FROM ochrana_uzemi.maloplosna_uzemi
      WHERE ST_Intersects(maloplosna_uzemi.geom, katastralniuzemi.geom)
      LIMIT 1
   ) xx;

.. tip:: Upravte dotaz tak, aby vybral pouze katastrální území, na kterých je
         více než pět maloplošných ZCHÚ.


GROUP BY podle primárního klíče
===============================

Pokud použijeme v klauzuli :sqlcmd:`GROUP BY` primární klíč, umožní dotaz vybrat
všechny podřízené položky. To je užitečné, pokud chceme vybrat pouze unikátní
záznamy.

Pokud provedeme :sqlcmd:`JOIN` katastrálních území a maloplošných ZCHÚ, budeme
mít ve výsledku pro každé KÚ tolik záznamů, s kolika MZCHÚ má nenulový průnik.

.. code-block:: sql

   SELECT
   katastralniuzemi.kod
   , count(*)
   FROM ruian.katastralniuzemi
   JOIN ochrana_uzemi.maloplosna_uzemi
   ON ST_Intersects(katastralniuzemi.geom, maloplosna_uzemi.geom)
   GROUP BY katastralniuzemi.kod
   HAVING count(*) > 1
   ;

Pokud v klauzuli :sqlcmd:`GROUP BY` použijeme primární klíč a v :sqlcmd:`SELECT`
dáme pouze záznamy této tabulky a agregační funkce, dostaneme unikátní záznamy.

.. code-block:: sql

   SELECT
   katastralniuzemi.*
   , count(*)
   FROM ruian.katastralniuzemi
   JOIN ochrana_uzemi.maloplosna_uzemi
   ON ST_Intersects(katastralniuzemi.geom, maloplosna_uzemi.geom)
   GROUP BY katastralniuzemi.ogc_fid;

Klastrování
===========

Ve verzi posgisu 2.3.0 a vyšší už je možné najít funkce na klastrování,
například :pgiscmd:`ST_ClusterKMeans`. Je to však horká novinka a nese s sebou
některé nevýhody (například výsledek vracený jako *GEOMETRY COLLECTION* může
působit problémy u velkých vrácených klastrů.

Vyzkoušíme si některé, z výše uvedených postupů, na ukázce klastrování. Jedná se
o poměrně typickou úlohu, na kterou můžete narazit například v souvislosti s
potřebou zobrazit velké množství prvků na aplikaci.

Zadání
^^^^^^

Z bodů v tabulce :dbtable:`ruian_praha.adresnimista` vytvořte skupiny tak, aby
mezi body byla vzdálenost menší, než třicet metrů a zároven nebyl žádný bod
nepatřící do skupiny blíže, než třicet metrů k libovolnému bodu ve skupině.

Řešení
^^^^^^

.. code-block:: sql


   CREATE INDEX ON ruian_praha.adresnimista USING btree(psc);

   BEGIN;

   ALTER TABLE ruian_praha.adresnimista ADD grupa int;

   DO $$
      DECLARE
      _grupa int := 1;
      r record;
      _ogc_fid int;
      BEGIN
         LOOP
            _ogc_fid := ogc_fid
            FROM ruian_praha.adresnimista
            WHERE psc = 14000
            AND grupa IS NULL
            LIMIT 1;

            RAISE NOTICE '%', _ogc_fid;

            IF _ogc_fid IS NULL THEN exit; END IF;

            WITH recursive klastr AS (
               SELECT ogc_fid FROM
               ruian_praha.adresnimista
               WHERE ogc_fid = _ogc_fid
               UNION
               SELECT 
               a.ogc_fid 
               FROM ruian_praha.adresnimista a
               , LATERAL (
                  SELECT True
                  FROM 
                  (
                     SELECT * 
                     FROM klastr 
                     JOIN ruian_praha.adresnimista a2 USING (ogc_fid)
                     WHERE a.geom && ST_Expand(a2.geom, 30)
                     AND a2.ogc_fid != a.ogc_fid
                  ) bb
                  WHERE (bb.geom <-> a.geom) <= 30
                  LIMIT 1
               ) filtr
               WHERE a.psc = 14000
            )
            UPDATE ruian_praha.adresnimista
            SET grupa = _grupa
            WHERE ogc_fid IN (
               SELECT ogc_fid FROM klastr)
            ;

            _grupa := _grupa + 1;

         END LOOP;
      END
      $$;

   COMMIT;

Rozbor
^^^^^^

Kostrou dotazu je anonymní blok kódu, který obsahuje smyčku.

.. code-block:: sql

   DO $$
      DECLARE
      _grupa int := 1;
      r record;
      _ogc_fid int;
      BEGIN
         LOOP
            _ogc_fid := ogc_fid
            FROM ruian_praha.adresnimista
            WHERE psc = 14000
            AND grupa IS NULL
            LIMIT 1;

            RAISE NOTICE '%', _ogc_fid;

            IF _ogc_fid IS NULL THEN exit; END IF;

            UPDATE ruian_praha.adresnimista
            SET grupa = _grupa
            WHERE ogc_fid IN (
               SELECT ogc_fid FROM klastr)
            ;

            _grupa := _grupa + 1;

         END LOOP;
      END
      $$;

Na začátku každého cyklu se načte hodnota primárního klíče záznamu, který má
poštovní směrovací číslo 14000 (omezení na psč je kvůli rychlosti, bez něj by
analýza trvala příliš dlouho a pro účely demonstrace to není třeba) a nemá
vyplněné číslo skupiny. V případě, že je číslo grupy vyplněno u všech
relevantních záznamů a tudíž je hodnota proměnné NULL, tak se smyčka přeruší.

Na konci smyčky se aktualizuje číslo skupiny pro všechny prvky, které sdílejí
skupinu s vybraným prvkem a číslo skupiny se navýší.

.. note:: Klauzule :sqlcmd:`RAISE NOTICE` slouží k vypsání aktuální hodnoty
          proměnné.

Výběr prvků ve skupině je proveden pomocí rekurzivního :pgsqlcmd:`CTE
<queries-with>`. K vybraným prvkům jsou přidány všechny prvky v zadané
vzdálenosti. Aby nebyly přidávány znova tytéž prvky zajišťuje klauzule
:sqlcmd:`UNION`, která přidává jen nové prvky (což ale znamená, že v každém
cyklu jsou znova a znova vybírány ty samé prvky, což není uplně efektivní, dotaz
by pravděpodobně bylo možné ještě zoptimalizovat). K filtrování je použit
:sqlcmd:`LATERAL`, který je počítán zvlášť pro každý řádek. Do výběru je tedy
přidán, každý řádek, pro který už ve výběru existuje alespoň jeden bod splňující
podmínku. Předvýběr je proveden pomocí operátoru :sqlcmd:`&&` a funkce
:sqlcmd:`ST_Expand`.

.. code-block:: sql

   WITH recursive klastr AS (
      SELECT ogc_fid FROM
      ruian_praha.adresnimista
      WHERE ogc_fid = _ogc_fid
      UNION
      SELECT 
      a.ogc_fid 
      FROM ruian_praha.adresnimista a
      , LATERAL (
         SELECT True
         FROM 
         (
            SELECT * 
            FROM klastr 
            JOIN ruian_praha.adresnimista a2 USING (ogc_fid)
            WHERE a.geom && ST_Expand(a2.geom, 30)
            AND a2.ogc_fid != a.ogc_fid
         ) bb
         WHERE (bb.geom <-> a.geom) <= 30
         LIMIT 1
      ) filtr
      WHERE a.psc = 14000
   )
   UPDATE ruian_praha.adresnimista
   SET grupa = _grupa
   WHERE ogc_fid IN (
      SELECT ogc_fid FROM klastr)
   ;
