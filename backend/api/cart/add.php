<?php
// POST { product_id, variation_id, quantity }
require '../../includes/auth_check.php';
require '../../config/db.php';
require_login();
$data = json_decode(file_get_contents("php://input"), true);
$product_id = (int)($data['product_id'] ?? 0);
$variation_id = isset($data['variation_id']) ? (int)$data['variation_id'] : null;
$quantity = max(1, (int)($data['quantity'] ?? 1));

$stockStmt = $pdo->prepare("SELECT stock_qty FROM products WHERE product_id = ? AND is_active = 1");
$stockStmt->execute([$product_id]);
$stock = $stockStmt->fetchColumn();
if ($stock === false) {
    http_response_code(404);
    echo json_encode(["error" => "Product not found"]);
    exit;
}

$cartStmt = $pdo->prepare("SELECT COALESCE(SUM(quantity), 0) FROM cart_items WHERE user_id = ? AND product_id = ? AND (variation_id <=> ?)");
$cartStmt->execute([$_SESSION['user_id'], $product_id, $variation_id]);
$existingQty = (int)$cartStmt->fetchColumn();
if ($existingQty + $quantity > (int)$stock) {
    http_response_code(422);
    echo json_encode(["error" => "Only {$stock} item(s) available"]);
    exit;
}

$stmt = $pdo->prepare("INSERT INTO cart_items (user_id, product_id, variation_id, quantity) VALUES (?, ?, ?, ?)");
$stmt->execute([$_SESSION['user_id'], $product_id, $variation_id, $quantity]);
echo json_encode(["success" => true]);
