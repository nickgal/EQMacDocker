-- Turn off Quarm's respawn reduction system so every spawn uses the respawn
-- time in spawn2. See README.md in this folder.
UPDATE rule_values SET rule_value = 'false'
WHERE rule_name = 'Quarm:EnableRespawnReductionSystem';
