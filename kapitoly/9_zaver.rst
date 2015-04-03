A co dál?
=========

.. todo::

Přenos dat
----------

.. notecmd:: Export vybrané tabulky do formátu PGDump

   .. code-block:: bash

      pg_dump pokusnik -t ukol_1.budovy -f stav_objekty.dump -Fc -Z 7

.. notecmd:: Import PGDump dávky do databáze

   .. code-block:: bash

      pg_restore -d pokusnik stav_objekty.dump

Pohledy a materializované pohledy
---------------------------------

Vlastní funkce
--------------

* R
