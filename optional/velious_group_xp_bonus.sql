-- Replace Quarm's larger group experience bonus with the Velious-era bonus.
-- See README.md in this folder.
UPDATE rule_values SET rule_value = 'false'
WHERE rule_name = 'Quarm:BonusGroupEXPOverride';
