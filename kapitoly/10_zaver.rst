A co dál?
=========

Přenos dat mezi databázemi
--------------------------

.. notecmd:: Export vybrané tabulky do formátu PGDump

   .. code-block:: bash

      pg_dump pokusnik -t ukol_1.budovy -f stav_objekty.dump -Fc -Z 7 -x

.. notecmd:: Import PGDump dávky do databáze

   .. code-block:: bash

      pg_restore -d pokusnik -x -O stav_objekty.dump

Doporučená konfigurace PostgreSQL
---------------------------------

::

   shared_buffers = 128MB      (default is 24MB)
   temp_buffers = 32MB         (default is 8MB)
   work_mem = 8MB              (default is 1MB)
   maintenance_work_mem = 32MB (default is 16MB)
   max_stack_depth = 4MB       (default is 2MB)
   checkpoint_segments = 24    (default is 3)
