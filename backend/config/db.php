<?php
/**
 * Database connection (XAMPP / MySQL)
 * Adjust credentials to match your local XAMPP setup.
 */
$DB_HOST = "localhost";
$DB_NAME = "stationery_shop";
$DB_USER = "root";
$DB_PASS = "";           // default XAMPP root password is empty

try {
    $pdo = new PDO(
        "mysql:host=$DB_HOST;dbname=$DB_NAME;charset=utf8mb4",
        $DB_USER,
        $DB_PASS,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed: " . $e->getMessage()]);
    exit;
}
