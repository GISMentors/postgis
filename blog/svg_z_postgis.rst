###########################
Generujeme `SVG` z POSTGISu
###########################

************************
Zastoupení dřevin po ORP
************************

Motivace
========

Mezi funkcemi PostGISu pro výstup je funkce `ST_AsSVG <http://postgis.net/docs/ST_AsSVG.html>`_. `SVG`, neboli škálovatelná grafika. Není předmětem následujícího postu rozberírat do podrobna výhody a nevýhody tohoto formátu, takže jen velmi stručně. `SVG` se dá vkládat přímo do html, dá se stylovat pomocí kaskádových stylů a výborně spolupracuje s javascriptem. Vykresluje se přímo na prohlížeči. Je ovšem třeba pamatovat na to, že ne každý prohlížeč vykreslí `SVG` a některé prohlížeče nedovedou pracovat správně se všemi prvky a jejich vlastnostmi. S `SVG` je možné ve webové prezentaci pracovat interaktivně a protože se jedná o vektorovou grafiku, při zvětšení nedochází k převzorkování. Na druhou stranu pro všechna měřítka se posílá stejně velký soubor, vykreslování opravdu velkého počtuprvků, nebo hodně složitých prvků může být zátěž pro prohlížeč a práce s takovým souborem nebude plynulá.

`SVG` je vhodné pro tvorbu interaktivních kartodiagramů, grafů, přehledových map. Pro tvorbu složitějších kartografických prezentací není tento formát optimální.

`SVG` je formát založený na `XML`, můžeme tedy, podle libosti, využívat funkce PostgreSQL pro práci s tímto formátem.

Zadání
======

Občas se mě moji přátelé ptají na to, jaká data dáváme z ÚHÚL. Proto se podíváme, když se někde řekne "jasan", kolik jich roste. Budeme pracovat s grafikou ORP.

Import dat
==========

Ve své oblíbené databázi pokusník jsem si vytvořil schéma na hraní.
::

   pokusnik=# create schema hratky_se_svg;

Wgetnu si RUIAN s generalizovanými hranicemi vyšších územně správních celků.
::

   wget http://vdp.cuzk.cz/vymenny_format/soucasna/20141130_ST_UKSG.xml.gz


A z toho vyberu ORP a nahrno celou parádu do postgre
::

   ogr2ogr -f PGDump /dev/stdout -a_srs 'EPSG:5514' 20141130_ST_UKSG.xml.gz Orp \
   -nln hratky_se_svg.orpecka \
   | psql pokusnik 2> er


.. note:: Použiji formát PGDump, místo PostgreSQL, protože na mé distribuci zlobí přidávání více sloupců s geometrií.

Jako numeriku použijeme data o stavu lesa za rok 2013::

   wget http://www.uhul.cz/images/ke_stazeni%5CSLHP/2013.rar


Data jsou, bohužel, v poměrně pitomém formátu xlsx, takže budeme muset trochu čarovat, abychom vykuchali potřebné údaje. K čtení xlsx použijeme utilitu gnumeric `ssconvert`.

Rozrarujeme si stažené soubory a v něm najdeme zararované výkazy. Vybereme výkazy po orp a opět je rozrarujeme.
::

   OLDIFS=$IFS;
   IFS=`echo -en "\n\n"`;
   find *.xlsx | while read ff; do
   ssconvert --export-type=Gnumeric_stf:stf_assistant \
   -O 'separator=; eol=unix sheet=dřeviny quoting-mode=never format=raw' \
   $ff;
   done 2> err

   IFS=$OLDIFS;

   find *.xlsx | wc -l
   find *.txt | wc -l

V rychlosti si vysvětleme, co jsem v této dávce provedl. Protože jsou v názvech kulišácky použité mezery, musím přenastavit proměnnou prostředí `IFS`, abych mohl použít smyčku. Aktuální hodnotu IFS si proto uložím do proměnné OLDIFS. Následně ve while smyčce projdu všechny soubory xlsx a proženu je přes ssconvert. Ssconvert je jak již bylo řečeno utilita distribuovaná společně s kancelářskou sadou libreoffice a slouží k převodům mezi formáty. Pomocí `--export-type=Gnumeric_stf:stf_assistant` si vyberu výstupní formátu jako konfigurovatelný textový soubor. Za přepínačem `-O` následují nastavení výstupu. Já si nastavil oddělovač na středník, konce řádků na unixové, zrušil jsem uvozovkování a formátování. Potom jsem uvedl IFS do původního stavu a srovnal počet vstupních a výstupních souborů, protože se mi v logu `err` objevily chyby. Pokud bych chtěl s těmito daty nějak vážně pracovat, pochopitelně bych se s takto povrchní kontrolou nespokojil.

.. note:: ÚHÚL bohužel používá číselník ORP podle ČSÚ, takže k párování nemůžeme použít kódy. Podle ČUZK je navíc o jedno ORP méně, proto nebudeme mít numeriku ke všem polygonům.

Data budou muset někde bydlet, vyrobíme pro ně tabulky.
::

   SET SEARCH_PATH = hratky_se_svg, public;

   CREATE SEQUENCE id_orp_seq;

   CREATE TABLE soubory_slhp(
      id_orp int NOT NULL DEFAULT nextval('id_orp_seq') PRIMARY KEY
      , nazev varchar(255)
   );


   CREATE FUNCTION f_id_orp() RETURNS BIGINT LANGUAGE SQL AS
   $$
   SELECT last_value FROM hratky_se_svg.id_orp_seq;
   $$
   ;

   CREATE TABLE slhp(
      id_orp int NOT NULL DEFAULT f_id_orp()
      , drevina varchar(255)
      , plocha_ha float
      , plocha_proc float
      , zasoba_m3 float
      , zasoba_proc float
      , avb float
      , stredni_vek float
   );


   CREATE INDEX ON slhp(id_orp);

.. note:: Tady je použitý jeden takový šikovný (leč zrádný trik). Budeme střídavě nahrávat do dvou tabulek, do první název souboru a do druhé data, přičemž u druhé tabulky se nám automaticky vloží hodnota naposledy vloženého záznamu. Pokud se ovšem něco pokazí a hodnota do první tabulky se nevloží, budeme mít špatně spárované hodnoty, protože budou mít id posledního úspěšně zapsaného záznamu.

Nahrajeme data do tabulek
::

   OLDIFS=$IFS;
   IFS=`echo -en "\n\n"`;

   find *.txt | while read ff; do 
      head -n 1 $ff | cut -d ';' -f 1 | psql -c "COPY hratky_se_svg.soubory_slhp (nazev) FROM STDIN" pokusnik;

      tail -n +8 $ff | sed 's/,/./g' | 
      psql -c "COPY hratky_se_svg.slhp (drevina, plocha_ha, plocha_proc, zasoba_m3, zasoba_proc, avb, stredni_vek) 
      FROM STDIN WITH DELIMITER ';' NULL ''" pokusnik;
   done 2> err

   IFS=$OLDIFS;

Z prvního řádku získáme název ORP a zkop9rujeme do databáze. Z každého listu vezmeme řádky od osmého výše a zkopírujeme do databáze, musíme však přenastavit DELIMITER, tedy oddělovač záznamů na středník a zápis hodnoty  NULL na prázdný řetězec.

Srovnáme, co nám chybí.
::

   SELECT nazev FROM orpecka 
   EXCEPT 
   SELECT regexp_replace(nazev, 'ORP \d{4} \- ','') FROM soubory_slhp;

Je to `Hlavní město Praha`. Zjevně bude mít nějaký vlastní status. Nevadí. Spárujeme si to.

.. note:: Pro kontrolu doporučuji provést porovnání EXCEPTem i na druhou stranu.

Párování můžeme provést třeba takto.
::


   ALTER TABLE orpecka ADD slhp_id_orp int;

   UPDATE orpecka o SET slhp_id_orp = id_orp
   FROM soubory_slhp s WHERE o.nazev =  regexp_replace(s.nazev, 'ORP \d{4} \- ','');


.. note:: V tomto případě nemá cenu pro něco málo přes dvěstě záznamů nový sloupec indexovat.


Komu se nelení, tomu se jasaní
==============================

*Vyrobobíme si mapku zastoupení jasanů*

Co vrací `ST_AsSVG`
-------------------

Takže, co tedy vrací?
::

   SELECT ST_AsSVG(generalizovanehranice) FROM hratky_se_svg.orpecka LIMIT 1;

Ale to nevypadá jako `XML`! Ano, jistě. Není to totiž celé svg, pouze zápis vektorových geometrií jednotlivých prvků. Je to kvůli tomu, že budeme chtít prvkům určovat jejich grafickou reprezentaci. Tloušťku čar, barvu a tak dále.

Element path
------------

Použijeme xml funkce postgisu k sestavení kompletního elementu path.
::

   SET SEARCH_PATH = hratky_se_svg, public;

   SELECT XMLELEMENT(NAME path,
      XMLATTRIBUTES(
         ST_AsSVG(generalizovanehranice, 0, 1) AS d
         , 'black' AS stroke
         , 50 AS "stroke-width"
         , 'none' AS fill
      )
   ) svg_path

   from orpecka;

Tady se nám již vrací xml elementy. Co jsem to právě povedl? Funkce `XMLELEMENT` vyrobí, jak již název napoví elemenmt xml. Pomocí fce `XMLATTRIBUTES` tento element naplníme nějakými atributy. První atribut pojmenujeme `d` a naplníme ho výstupem z funkce `ST_AsSVG`. Všiměte si druhého a třetího parametru funkce `ST_AsSVG`. Druhý parametr rozlišuje, jestli mají být souřadnice lomových bodů v absolutních hodnotách, nebo relativně k prvku. Nula značí relativně. Druhý je počet desetinných míst. Jednička znamená jedno desetinné místo. Přesnost na deset centimetrů je u generalizovaných hranic ORP více než dostačující. Teoreticky by bylo možné posunout pomocí ST_Translate celou geometrii na souřadnice 0.0, případně to přetransformovat do SRS s jinými jednotkami pomoci ST_Transform. Tím se však ted nebudeme zdržovat.

První obrázek
-------------

Nyní si vytvořené prvky umístíme do prvku svg, kterému nastavíme atributy pro správné zobrazení.
::

   SET SEARCH_PATH = hratky_se_svg, public;

   \a \t \o orp.svg

   SELECT 
   XMLELEMENT(NAME svg,
      XMLATTRIBUTES(
      600 AS height
      , 800 AS width
      , array_to_string(ARRAY[MIN(ST_XMIN(generalizovanehranice)) - 2500, -1 * (MAX(ST_YMAX(generalizovanehranice))) - 2500
         , (@(MAX(ST_XMAX(generalizovanehranice)) - MIN(ST_XMIN(generalizovanehranice)))) + 5000
         , (@(MAX(ST_YMAX(generalizovanehranice)) - MIN(ST_YMIN(generalizovanehranice)))) + 5000], ' ') AS "viewBox"
         , 'http://www.w3.org/2000/svg' AS xmlns, '1.1' AS version
      )
      , XMLAGG (
         XMLELEMENT(NAME path,
            XMLATTRIBUTES(
               ST_AsSVG(generalizovanehranice, 0, 0) AS d
               , 'black' AS stroke
               , 300 AS "stroke-width"
               , 'none' AS fill
            )
         ) 
      )
   )

   from orpecka;

   \o \a \t

`Výsledek <orp.svg>`_

Co se tady dělo?

V prvním řádku jsem nastavil search_path na složku s daty a public (v publicu jsou funkce postgisu). Dále jsem vypnul alignování výpisu a nastavil vypisování jen na výslekdy dotazu. Soubor pro výstup jsem nastavil na `orp.svg`. Připomínám, že \\a \\t a \\o jsou metapříkazy psql, tudíž je třeba pracovat z psql konzole. V adminu toto nejspíš nebude fungovat. Nicméně můžete pustit dávku bez těchto metapříkazů a výstup uložit do souboru jinou cestou. Celý výsledek je uzavřen v elementu nazvaném svg. Tomuto elementu přiřadíme výšku a šířku a viewbox, nakonec zařadíme namespace a verzi svg. 

U viewboxu se trochu zdržíme. SVG maluje do třetího kvadrantu (neptejte se mě proč) a to tak, že x je směr doprava a ypsilon mazaně dolů. Viewbox se uvádí jako čtveřice mezerou oddělených hodnot ve tvaru "xmin ymin šířka výška". Viewbox jsem protáhnul o pět kilometrů, tedy dva a půl na každé straně. Operátor `\@` je absolutní hodnota.

Poté zagreguji do elementu svg všechny elementy path všechny elementy path (šířku linie jsem zvětšil na 300).

Nakonec zavřu soubor a zpět zapnu vypisování v psql.

Barvičky podle numeriky
-----------------------

::

   SET SEARCH_PATH = hratky_se_svg, public;


   \a \t \o orp_jasan.svg

   SELECT 
   XMLELEMENT(NAME svg,
      XMLATTRIBUTES(
      600 AS height
      , 800 AS width
      , array_to_string(ARRAY[MIN(ST_XMIN(generalizovanehranice)) - 2500, -1 * (MAX(ST_YMAX(generalizovanehranice))) - 2500
         , (@(MAX(ST_XMAX(generalizovanehranice)) - MIN(ST_XMIN(generalizovanehranice)))) + 5000
         , (@(MAX(ST_YMAX(generalizovanehranice)) - MIN(ST_YMIN(generalizovanehranice)))) + 5000], ' ') AS "viewBox"
         , 'http://www.w3.org/2000/svg' AS xmlns, '1.1' AS version
      )
      , XMLAGG (
         XMLELEMENT(NAME path,
            XMLATTRIBUTES(
               ST_AsSVG(generalizovanehranice, 0, 0) AS d
               , 'black' AS stroke
               , 300 AS "stroke-width"
               , 'rgb('||(2.55*(100-(plocha_proc*4)))::int||',255,'||(2.55*(100-(plocha_proc * 4)))::int||')' AS fill
            )
         ) 
      )
   )

   FROM orpecka o, slhp s
   WHERE o.slhp_id_orp = s.id_orp
   AND drevina = 'jasan';

   \o \a \t


`Výsledek obarvený podle jasanu <orp_jasan.svg>`_

TODO


Měnění csssek s vybarvenim pomocí javascriptu

Popis ORP na hower

#Měnění barev javascriptem z JSONU

Generalizace

http://strk.keybit.net/blog/2012/04/13/simplifying-a-map-layer-using-postgis-topology/

#Posun do kilometrovýho křováka a souřadnice 0.0.

Zoom na vybraný ORP? Nebo spíš jen zvýraznění.


<?xml-stylesheet type="text/css" href="svg-stylesheet.css" ?>

http://tutorials.jenkov.com/svg/svg-and-css.html


http://stackoverflow.com/questions/24086973/how-can-you-change-the-attached-css-file-with-javascript

<link id="myStyleSheet" href="stylesheet.css" rel="stylesheet" type="text/css" />

<script type="text/javascript">
    function styler(attr){
        var href;
        switch(attr){
            case'1':href = "stylesheet1.css";break;
            case'2':href = "stylesheet2.css";break;
            case'3':href = "stylesheet3.css";break;
            case'4':href = "stylesheet.css";break;
            default:;break;
        }
        document.getElementById('myStyleSheet').href = href;
    }
</script>


Extension unaccent; !!!!

<!DOCTYPE html>
<html>
<body>

<p id="demo" onclick='{document.getElementById("demo").style.color = "red";}'>Click me to change my text color.</p>

<p>A function is triggered when the p element is clicked. The function sets the color of the p element to red.</p>



</body>
</html>

Plánované posty
===============

Zastoupení dřevin a appka v SVG
-------------------------------

* Import ORP z RUIAN a numeriky z uhulích excelů - Jelen téměř hotový

* Jednoduché generování SVG a obarvení podle zastoupení jasanu - Jelen v procesu

* Generalizace v topologii - Jelen

* Obarvení generalizovaný mapky pomocí kaskádovejch stylů, přepínání cssek javascriptem - Jelen

* Obarvení svg z JSONU javascriptemi - Jelen a Jáchym

* Manipulace se SVG pomocí d3js - Jáchym

Multithread načítání v psql a bashi
-----------------------------------

Jelen





