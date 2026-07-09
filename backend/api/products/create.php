<?php
// POST (admin only) { category_id, name, description, price, stock_qty, image_url }
require '../../includes/auth_check.php';
require '../../config/db.php';
require '../../includes/functions.php';
require_admin();
$data = json_decode(file_get_contents("php://input"), true);
$stmt = $pdo->prepare("INSERT INTO products (category_id, name, description, price, stock_qty, image_url) VALUES (?, ?, ?, ?, ?, ?)");
$stmt->execute([$data['category_id'], $data['name'], $data['description'], $data['price'], $data['stock_qty'], $data['image_url']]);
log_action($pdo, $_SESSION['user_id'], "Created product {$data['name']}");
echo json_encode(["success" => true, "product_id" => $pdo->lastInsertId()]);
