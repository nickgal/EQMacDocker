UPDATE rule_values SET rule_value='false' WHERE rule_name='Quarm:EnableAdminChecks';
UPDATE rule_values SET rule_value='6' WHERE rule_name='World:MaxClientsPerIP';
UPDATE rule_values SET rule_value='6' WHERE rule_name='World:AccountSessionLimit';

UPDATE launcher SET dynamics=0 WHERE name='dynzone2';
UPDATE launcher SET dynamics=0 WHERE name='zone1';
UPDATE launcher SET dynamics=0 WHERE name='zone2';
UPDATE launcher SET dynamics=0 WHERE name='zone3';

-- Upstream runs every zone statically. Here the dynzone1 launcher keeps idle
-- dynamic zone processes running, and world assigns a zone to one of them when
-- a player enters it. This rule has to be off for world to do that.
UPDATE rule_values SET rule_value='false' WHERE rule_name='World:DontBootDynamics';
