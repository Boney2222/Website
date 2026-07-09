<?php
// GET ?id=123 -> single product + its variations
require '../../config/db.php';
require '../../config/config.php';
$id = $_GET['id'];
$stmt = $pdo->prepare("SELECT * FROM products WHERE product_id = ?");
$stmt->execute([$id]);
$product = $stmt->fetch();
$vstmt = $pdo->prepare("SELECT * FROM product_variations WHERE product_id = ?");
$vstmt->execute([$id]);
$product['variations'] = $vstmt->fetchAll();
echo json_encode($product);
