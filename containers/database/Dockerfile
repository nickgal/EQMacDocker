FROM mariadb:10.5

ADD Server/utils/sql/database_full/quarm_2023-08-28-22_03.tar.gz /docker-entrypoint-initdb.d
RUN rm /docker-entrypoint-initdb.d/drop_system.sql

ADD Server/loginserver/login_util/tblloginserversettings.sql /docker-entrypoint-initdb.d
ADD Server/loginserver/login_util/updates/2023_07_27_tblLoginServerAccounts.sql /docker-entrypoint-initdb.d/x_2023_07_27_tblLoginServerAccounts.sql

ADD containers/database/auto_create.sql /docker-entrypoint-initdb.d/z_auto_create.sql
ADD containers/database/launcher_boats.sql /docker-entrypoint-initdb.d/z_launcher_boats.sql
ADD containers/database/quake_data.sql /docker-entrypoint-initdb.d/z_quake_data.sql
