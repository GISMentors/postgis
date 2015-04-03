Topologie
=========

.. todo:: nedokonceno

*PostGIS vznikl jako projekt implementující standard OGC* `Simple
Features <http://www.opengeospatial.org/standards/sfa>`_ *pro práci s
vektorovými daty ve formě jednoduchých prvků. Od verze 2.0 nicméně
umožnuje práci s vektorovými daty také v topologické formě.*

.. warning:: Podporováno od verze PostGIS 2.0 a vyšší

Rozšíření pro topologická vektorová data nahrajeme příkazem:

.. code-block:: sql
   
   CREATE EXTENSION postgis_topology;

Topologický datový model
------------------------

Podrobné informace k tomuto tématu `zde
<http://geo.fsv.cvut.cz/~gin/uzpd/uzpd.pdf#146>`_.

Rozdíl mezi datovým modelem jednoduchých geoprvků (simple features) a
topologickým modelem si ukážeme na případě dvou sousedících polygonů.

Užitečné odkazy
---------------

* http://freegis.fsv.cvut.cz/gwiki/PostGIS_Topology
* http://grasswiki.osgeo.org/wiki/PostGIS_Topology
