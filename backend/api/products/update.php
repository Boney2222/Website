<?php
// PUT (admin only) { product_id, name, price, stock_qty, ... }
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
$oldStmt = $pdo->prepare("SELECT name, price, stock_qty FROM products WHERE product_id = ?");
$oldStmt->execute([$data['product_id'] ?? 0]);
$old = $oldStmt->fetch();
if (!$old) {
    http_response_code(404);
    echo json_encode(["error" => "Product not found"]);
    exit;
}
$stmt = $pdo->prepare("UPDATE products SET category_id=?, name=?, description=?, price=?, stock_qty=?, image_url=? WHERE product_id=?");
$stmt->execute([$data['category_id'], $data['name'], $data['description'], $price, $stock, $data['image_url'], $data['product_id']]);
log_action($pdo, $_SESSION['user_id'], "Updated product {$data['name']} (price {$old['price']} -> {$price}, stock {$old['stock_qty']} -> {$stock})");
echo json_encode(["success" => true]);
