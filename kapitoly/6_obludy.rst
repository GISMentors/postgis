Praktické příklady
==================

Nejbližší bod
-------------

*Protože Vaše agentura pro boj s vesmírnými obludami nemá dostatek peněz, vybavuje své agenty pouze turistickými mapkami, které se prodávají na nádraží, najděte ke každému bodu nejbližší adresu.*

Zadání
^^^^^^

Ke každému z bodů v tabulce **ukol_1.vesmirne_zrudice** nejděte nejbližší bod z tabulky **ukol_1.adresy**.

Rozbor
^^^^^^

Nejdříve zkontrolujeme, zda je tabulka s adresními body patřičně oindexovaná.

.. code-block:: sql

   \d+ ukol_1.adresy

::

   Indexy:
       "adresy_pk" PRIMARY KEY, btree (ogc_fid)
       "adresy_adresnibod_geom_idx" gist (adresnibod)
       "adresy_hasici_geom_idx" gist (hasici)
       "adresy_zachranka_geom_idx" gist (zachranka)



S ohledem na to, že pracujeme s body, vystačíme si s operátory.

.. code-block:: sql

   SET SEARCH_PATH = ukol_1, public;
   --public musí být proto, že v něm jsou uložený PostGIS

   SELECT a.kod, v.id, a.adresnibod<->v.geom_p vzdalenost
   FROM adresy a, vesmirne_zrudice v 
   WHERE adresnibod IS NOT NULL
   LIMIT 200;


K výběru nejbližšího bodu použijeme *LIMIT*

.. code-block:: sql

   SELECT a.kod, v.id, a.adresnibod<->v.geom_p vzdalenost
   FROM adresy a, vesmirne_zrudice v 
   WHERE adresnibod IS NOT NULL
   AND v.id = 1
   ORDER BY a.adresnibod<->v.geom_p
   LIMIT 1;

K výběru nejbližšího bodu ke každému z bodů můžeme použít několik cest.

Vnořený poddotaz:

.. code-block:: sql

   SELECT 
   id
   , (
      SELECT ARRAY[kod, adresnibod<->geom_p]  
      FROM ukol_1.adresy 
      WHERE adresnibod IS NOT NULL 
      ORDER by adresnibod<->geom_p 
      LIMIT 1
   ) FROM vesmirne_zrudice;

Common table expression s `window funkcí <http://www.postgresql.org/docs/9.3/static/tutorial-window.html>`_

.. code-block:: sql

   WITH cte AS
   (
      SELECT 
      ROW_NUMBER() 
      OVER (
         PARTITION BY v.id
         ORDER BY a.adresnibod<->v.geom_p 
      ) rn
      , v.id
      , a.kod
      , a.adresnibod<->v.geom_p vzdalenost

      FROM vesmirne_zrudice v,
      adresy a
   )

   SELECT * FROM cte WHERE rn = 1;

.. warning:: Elegantní řešení nemusí být však vždy to nejvýkonější. A to ani při optimalizaci.


.. code-block:: sql

   WITH cte AS
   (
      SELECT 
      ROW_NUMBER() 
      OVER (
         PARTITION BY v.id
         ORDER BY a.adresnibod<->v.geom_p 
      ) rn
      , v.id
      , a.kod
      , a.adresnibod<->v.geom_p vzdalenost

      FROM vesmirne_zrudice v,
      adresy a WHERE v.geom_p<->a.adresnibod < 200
   )

   SELECT * FROM cte WHERE rn = 1;

Window funkce v poddotazu

.. code-block:: sql

   SELECT * FROM 
   (
      SELECT 
      ROW_NUMBER() 
      OVER (
         PARTITION BY v.id
         ORDER BY a.adresnibod<->v.geom_p 
      ) rn
      , v.id
      , a.kod
      , a.adresnibod<->v.geom_p vzdalenost

      FROM vesmirne_zrudice v,
      adresy a WHERE v.geom_p<->a.adresnibod < 200
   ) a
   WHERE rn = 1;

Případně můžeme použít `anonymní blok kódu <file:///usr/share/doc/postgresql/html/sql-do.html>`_

.. code-block:: sql

   BEGIN;

   CREATE TABLE ukol_1.outp (id int, kod numeric(30), vzdalenost float);

   DO $$DECLARE r record;
   BEGIN
      FOR r IN
      SELECT id, geom_p
      FROM  vesmirne_zrudice v 
    LOOP
      INSERT INTO outp 
      SELECT r.id, kod, r.geom_p<->a.adresnibod 
      FROM adresy a 
      ORDER BY r.geom_p<->a.adresnibod
      LIMIT 1;
    END LOOP;
   END$$;

   SELECT * FROM outp;

   ROLLBACK;

.. tip:: Srovnejte *EXPLAIN ANALYZE*

Řešení
^^^^^^

.. code-block:: sql

   BEGIN;

   CREATE TABLE ukol_1.outp (id int
      , kod numeric(30)
      , vzdalenost float
      , cislodomovni int
      , cisloorientacni int
      , psc int
      , ulicekod bigint
      , stavebniobjektkod bigint
   );

   DO $$DECLARE r record;
   BEGIN
      FOR r IN
      SELECT id, geom_p
      FROM  vesmirne_zrudice v 
    LOOP
      INSERT INTO outp 
      SELECT r.id, kod
      , r.geom_p<->a.adresnibod
      , cislodomovni
      , cisloorientacni
      , psc
      , ulicekod
      , stavebniobjektkod
      FROM adresy a 
      ORDER BY r.geom_p<->a.adresnibod
      LIMIT 1;
    END LOOP;
   END$$;

   SELECT 
   o.*
   , u.nazev
   FROM outp o
   LEFT JOIN ulice u
   ON u.kod = ulicekod
   ORDER BY id;

   ROLLBACK;

Výběr bafrem
------------

*V případě, že se obludy vylíhnou, všechno živé v okruhu čtvrt kilometru se změní ve sliz. Najděte všechny ulice ve vzdálenosti 250 metrů od vejce, aby je bylo možné evakuovat.*

Zadání
^^^^^^

Vyberte všechny ulice v okruhu 250 metrů kolem každého bodu.

Rozbor
^^^^^^

V tabulce ulice nám nejspíš bude chybět index. Zkontrolujeme ho a pokud tam není, tak ho vytvoříme.

.. code-block:: sql

   CREATE INDEX ulice_geom_idx ON ulice USING gist (geom);

Ulice v okruhu 250 metrů můžeme vybrat buď bafrem,

.. code-block:: sql

   SELECT u.*, v.geom_p
   FROM ulice u,
   vesmirne_zrudice v
   WHERE ST_Relate(geom, ST_Buffer(geom_p, 250, 100), 'T********');

.. tip:: Vyzkoušejte místo ST_Relate ST_Intersects

optimalizovaná verze

.. code-block:: sql

   SELECT * FROM
   (
      SELECT u.*, v.geom_p
      FROM ulice u,
      vesmirne_zrudice v
      WHERE ST_Buffer(v.geom_p, 250, 100) && u.geom
   ) a 
   WHERE ST_Relate(geom, ST_Buffer(geom_p, 250, 100), 'T********');

nebo na základě vzdálenosti.

.. code-block:: sql

   EXPLAIN ANALYZE
   SELECT * FROM
   (
      SELECT u.*, v.geom_p
      FROM ulice u,
      vesmirne_zrudice v
      WHERE (v.geom_p<#>u.geom) <= 250
   ) a
   WHERE ST_Distance(geom, geom_p) <= 250;


Součet ploch v určitém okruhu
-----------------------------

*Nemáte dostatek agentů v terénu, nejspíše se nepodaří neutralizovat všechna vejce, seřaďte body podle počtu budov v ohrožené zóně, aby bylo možné minimalizovat škody.*

Zadání
^^^^^^

Vyberte budovy v okruhu 250 metrů kolem bodů z tabulky *vesmirne_zrudice*, zjistěte počet u každého bodu. Zjistěte plochu průniku u každého bodu. Zjistěte celkovou plochu všech zasažených podlaží.

Postup
^^^^^^

Nahrajeme do databáze budovy.

.. notecmd:: načtení dat z PGDump

   .. code-block:: bash

      wget http://46.28.111.140/gismentors/skoleni/data_postgis/stav_objekty.dump
      psql -f stav_objekty.dump pokusnik

Indexy už v tabulce jsou.

.. code-block:: sql

   SELECT 
   id
   , originalnihranice
   , ST_Intersection(originalnihranice, ST_Buffer(geom_p, 250, 100)) prunik
   , pocetpodlazi

   FROM
   (
      SELECT b.*, v.geom_p, v.id
      FROM budovy b,
      vesmirne_zrudice v
      WHERE (v.geom_p<#>b.originalnihranice) <= 250
      AND originalnihranice IS NOT NULL
   ) a
   WHERE ST_Relate(ST_Buffer(geom_p, 250, 100), originalnihranice, '2********');

Ale máme chybky v topologii

.. code-block:: sql

   SELECT * FROM budovy WHERE NOT ST_IsValid(originalnihranice) ;

Chyby můžeme opravit, nebo použít *ST_MakeValid* rovnou v dotazu.

.. code-block:: sql

   SELECT
   id
   , COUNT(*) pocet_budov
   , SUM(ST_Area(originalnihranice)) plocha_budov
   , SUM(ST_Area(prunik)) plocha_pruniku
   , SUM(ST_Area(prunik)*pocetpodlazi) plocha_zasazenych_podlazi
   , SUM(
      CASE WHEN ((ST_Area(prunik)) / (ST_Area(originalnihranice))) > 0.5 
         THEN 1
      ELSE 0
      END) pocet_zasazenych_vic_nez_z_poloviny
   FROM
   (
      SELECT 
      id
      , originalnihranice
      , ST_Intersection(ST_MakeValid(originalnihranice), ST_Buffer(geom_p, 250, 100)) prunik
      , pocetpodlazi

      FROM
      (
         SELECT b.*, v.geom_p, v.id
         FROM budovy b,
         vesmirne_zrudice v
         WHERE (v.geom_p<#>b.originalnihranice) <= 250
         AND originalnihranice IS NOT NULL
      ) a
      WHERE ST_Relate(ST_Buffer(geom_p, 250, 100), originalnihranice, '2********')
   )b
   GROUP BY id
   ORDER BY SUM(ST_Area(prunik)) DESC
   ;


U mnoha budov ovšem nemáme polygon, ale pouze definiční bod.

.. tip:: Navrhněte, jak upravit dotaz tak, aby se použily definiční body u budov, u kterých nemáme geometrii. Pro výpočet plochy můžete použít zastavěnou plochu.

Nejbližší bod 2
---------------

*U každého místa najděte nejbližší přístupové místo pro hasiče a záchranku mimo kontaminovanou zonu.*

Zadání
^^^^^^

V tabulce adresy jsou i body přístupových míst pro hasiče a záchranou službu. Navrhněte možné postupy, jak najít ke každému bodu nejližší přístupový bod pro hasiče a nejbližší přístupový bod pro záchranku, který je vzdálen více než 250 metrů od bodu.

