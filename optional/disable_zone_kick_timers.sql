-- Stop kicking players to server select after an hour in nexus, shadowhaven,
-- timorous and bazaar. See README.md in this folder.
UPDATE zone SET afk_kick_timer = 0 WHERE afk_kick_timer > 0;
