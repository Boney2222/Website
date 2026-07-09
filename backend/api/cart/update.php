<?php
// PUT { cart_item_id, quantity }
require '../../includes/auth_check.php';
require '../../config/db.php';
require_login();
$data = json_decode(file_get_contents("php://input"), true);
$quantity = max(1, (int)($data['quantity'] ?? 1));
$cart_item_id = (int)($data['cart_item_id'] ?? 0);

$itemStmt = $pdo->prepare("SELECT ci.product_id, p.stock_qty FROM cart_items ci JOIN products p ON p.product_id = ci.product_id WHERE ci.cart_item_id = ? AND ci.user_id = ?");
$itemStmt->execute([$cart_item_id, $_SESSION['user_id']]);
$item = $itemStmt->fetch();
if (!$item) {
    http_response_code(404);
    echo json_encode(["error" => "Cart item not found"]);
    exit;
}
if ($quantity > (int)$item['stock_qty']) {
    http_response_code(422);
    echo json_encode(["error" => "Only {$item['stock_qty']} item(s) available"]);
    exit;
}

$stmt = $pdo->prepare("UPDATE cart_items SET quantity=? WHERE cart_item_id=? AND user_id=?");
$stmt->execute([$quantity, $cart_item_id, $_SESSION['user_id']]);
echo json_encode(["success" => true]);
