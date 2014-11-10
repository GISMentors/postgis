

ogr2ogr -f "PostgreSQL" PG:"dbname=pokusnik" "http://services.cuzk.cz/wfs/inspire-cp-wfs.asp?service=WFS&request=GetFeature&version=2.0.0&srsName=urn:ogc:def:crs:EPSG::5514&typeNames=CP:CadastralZoning&featureid=CZ.605999" -nln katatest

