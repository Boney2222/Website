<?php
// PUT (admin only) { product_id, name, price, stock_qty, ... }
require '../../includes/auth_check.php';
require '../../config/db.php';
require '../../includes/functions.php';
require_admin();
$data = json_decode(file_get_contents("php://input"), true);
$stmt = $pdo->prepare("UPDATE products SET category_id=?, name=?, description=?, price=?, stock_qty=?, image_url=? WHERE product_id=?");
$stmt->execute([$data['category_id'], $data['name'], $data['description'], $data['price'], $data['stock_qty'], $data['image_url'], $data['product_id']]);
log_action($pdo, $_SESSION['user_id'], "Updated product {$data['name']}");
echo json_encode(["success" => true]);
