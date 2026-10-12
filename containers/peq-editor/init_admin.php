<?php
// Create the editor's login table and set the admin password from
// PEQ_EDITOR_PASSWORD. The editor's own sql/schema.sql would add admin/password.
// Its sql/expansion.sql is not needed: the Quarm zone table already has an
// expansion column.

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

$db = new mysqli(
    getenv('DB_HOST'),
    getenv('DB_USER'),
    getenv('DB_PASSWORD'),
    getenv('DB_NAME'),
    (int) (getenv('DB_PORT') ?: 3306)
);

$db->query("CREATE TABLE IF NOT EXISTS peq_admin (
    id INT(11) AUTO_INCREMENT PRIMARY KEY,
    login VARCHAR(30) NOT NULL,
    password VARCHAR(255) NOT NULL,
    administrator INT(11) NOT NULL DEFAULT '0'
)");

$stmt = $db->prepare("INSERT INTO peq_admin (id, login, password, administrator)
    VALUES (1, 'admin', MD5(?), 1)
    ON DUPLICATE KEY UPDATE login = 'admin', password = MD5(?), administrator = 1");
$password = getenv('PEQ_EDITOR_PASSWORD');
$stmt->bind_param('ss', $password, $password);
$stmt->execute();

echo "PEQ editor admin account ready\n";
