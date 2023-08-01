FROM mariadb:10.5

ADD Server/utils/sql/database_full/alkabor_2023-07-23-21_46.tar.gz /docker-entrypoint-initdb.d
ADD Server/loginserver/login_util/tblloginserversettings.sql /docker-entrypoint-initdb.d
RUN rm /docker-entrypoint-initdb.d/drop_system.sql

ADD containers/database/auto_create.sql /docker-entrypoint-initdb.d/z_auto_create.sql
ADD containers/database/launcher_boats.sql /docker-entrypoint-initdb.d/z_launcher_boats.sql
