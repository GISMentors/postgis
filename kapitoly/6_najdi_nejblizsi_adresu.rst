*Protože Vaše agentura pro boj s vesmírnými obludami nemá dostatek peněz, vybavuje své agenty pouze turistickými mapkami, které se prodávají na nádraží, najděte ke každému bodu nejbližší adresu. V případě, že se obludy vylíhnou, všechno živé v okruhu čtvrt kilometru se změní ve sliz. Najděte všechny ulice ve vzdálenosti 250 metrů od vejce, aby je bylo možné evakuovat. Nemáte dostatek agentů v terénu, nejspíše se nepodaří neutralizovat všechna vejce, seřaďte body podle počtu budov v ohrožené zóně, aby bylo možné minimalizovat škody.*

http://boundlessgeo.com/2011/09/indexed-nearest-neighbour-search-in-postgis/

select * into ttt from ukol_1.adresy where gid in (SELECT (SELECT gid from ukol_1.adresy where geom is not NULL order by geom<->geom_p limit 1) from vesmirne_zrudice );

