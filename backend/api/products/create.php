<?php
// POST (admin only) { category_id, name, description, price, stock_qty, image_url }
require '../../includes/auth_check.php';
require '../../config/db.php';
require '../../includes/functions.php';
require_admin();
$data = json_decode(file_get_contents("php://input"), true);
$price = (float)($data['price'] ?? -1);
$stock = (int)($data['stock_qty'] ?? -1);
if (trim((string)($data['name'] ?? '')) === '' || $price < 0 || $stock < 0) {
    http_response_code(422);
    echo json_encode(["error" => "Product name is required, and price/stock cannot be less than 0"]);
    exit;
}
$stmt = $pdo->prepare("INSERT INTO products (category_id, name, description, price, stock_qty, image_url) VALUES (?, ?, ?, ?, ?, ?)");
$stmt->execute([$data['category_id'], $data['name'], $data['description'], $price, $stock, $data['image_url']]);
log_action($pdo, $_SESSION['user_id'], "Created product {$data['name']} (price {$price}, stock {$stock})");
echo json_encode(["success" => true, "product_id" => $pdo->lastInsertId()]);
