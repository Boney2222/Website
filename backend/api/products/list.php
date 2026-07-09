<?php
// GET ?category=slug&search=term  -> list products (with category name, variations count)
require '../../config/db.php';
require '../../config/config.php';
$sql = "SELECT p.*, c.name AS category_name, c.slug AS category_slug FROM products p
        LEFT JOIN categories c ON p.category_id = c.category_id
        WHERE p.is_active = 1";
$params = [];
if (!empty($_GET['category'])) {
    $sql .= " AND c.slug = ?";
    $params[] = $_GET['category'];
}
if (!empty($_GET['search'])) {
    $sql .= " AND p.name LIKE ?";
    $params[] = "%" . $_GET['search'] . "%";
}
$sql .= " ORDER BY p.created_at DESC, p.product_id DESC";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
echo json_encode($stmt->fetchAll());
