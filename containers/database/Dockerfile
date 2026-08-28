FROM mariadb:lts

ADD Server/utils/sql/database_full/alkabor_2026-08-25-20_39.tar.gz /docker-entrypoint-initdb.d
RUN rm /docker-entrypoint-initdb.d/drop_system.sql

ADD containers/database/auto_create.sql /docker-entrypoint-initdb.d/z_auto_create.sql
ADD containers/database/launcher_boats.sql /docker-entrypoint-initdb.d/z_launcher_boats.sql
# not currently included in full database dumps
ADD Server/utils/sql/git/required/2025_05_26_Add_Detail_Player_Event_Logging.sql /docker-entrypoint-initdb.d/z_2025_05_26_Add_Detail_Player_Event_Logging.sql
