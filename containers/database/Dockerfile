FROM mariadb:10.5

ADD Server/utils/sql/database_full/quarm_2026-09-27-22_44.tar.gz /docker-entrypoint-initdb.d
RUN rm /docker-entrypoint-initdb.d/drop_system.sql

ADD Server/loginserver/login_util/tblloginserversettings.sql /docker-entrypoint-initdb.d
ADD Server/loginserver/login_util/updates/2023_07_27_tblLoginServerAccounts.sql /docker-entrypoint-initdb.d/x_2023_07_27_tblLoginServerAccounts.sql

ADD Server/utils/sql/git/required/2023_09_11_first_to_engage_table.sql /docker-entrypoint-initdb.d/y_2023_09_11_first_to_engage_table.sql
ADD Server/utils/sql/git/required/2023_11_25_qs_player_ks_log.sql /docker-entrypoint-initdb.d/y_2023_11_25_qs_player_ks_log.sql
ADD Server/utils/sql/git/required/2024_12_21_create_tbl_character_combination_unlocks.sql /docker-entrypoint-initdb.d/y_2024_12_21_create_tbl_character_combination_unlocks.sql
ADD Server/utils/sql/git/required/2024_12_23_player_events_tables.sql /docker-entrypoint-initdb.d/y_2024_12_23_player_events_tables.sql
ADD Server/utils/sql/git/required/2024_7_20_spell_buckets.sql /docker-entrypoint-initdb.d/y_2024_7_20_spell_buckets.sql
ADD Server/utils/sql/git/required/2025_3_23_created_account_inventory_table.sql /docker-entrypoint-initdb.d/y_2025_3_23_created_account_inventory_table.sql
ADD Server/utils/sql/git/required/2025_3_2_start_faction_hits.sql /docker-entrypoint-initdb.d/y_2025_3_2_start_faction_hits.sql
ADD Server/utils/sql/git/required/2026_09_25_character_blocked_buffs.sql /docker-entrypoint-initdb.d/y_2026_09_25_character_blocked_buffs.sql

ADD containers/database/auto_create.sql /docker-entrypoint-initdb.d/z_auto_create.sql
ADD containers/database/launcher_boats.sql /docker-entrypoint-initdb.d/z_launcher_boats.sql
ADD containers/database/other_fixes.sql /docker-entrypoint-initdb.d/z_other_fixes.sql 
