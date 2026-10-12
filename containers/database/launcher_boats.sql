-- Upstream now lists the boat zones under the zone3 launcher. Move them to the
-- dedicated boats launcher so they stay up permanently on the ports the boats
-- container exposes.
UPDATE `launcher_zones`
SET `launcher` = 'boats',
  `port` = CASE
  WHEN `zone` = 'erudnext' THEN 7375
  WHEN `zone` = 'erudsxing' THEN 7376
  WHEN `zone` = 'qeynos' THEN 7377
  WHEN `zone` = 'freporte' THEN 7378
  WHEN `zone` = 'oot' THEN 7379
  WHEN `zone` = 'butcher' THEN 7380
  WHEN `zone` = 'oasis' THEN 7381
  WHEN `zone` = 'nro' THEN 7382
  WHEN `zone` = 'firiona' THEN 7383
  WHEN `zone` = 'overthere' THEN 7384
  WHEN `zone` = 'timorous' THEN 7385
  WHEN `zone` = 'iceclad' THEN 7386
END
WHERE `zone` IN ('erudnext', 'erudsxing', 'qeynos', 'freporte', 'oot', 'butcher',
  'oasis', 'nro', 'firiona', 'overthere', 'timorous', 'iceclad');
