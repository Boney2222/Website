<?php
// GET ?id=order_id -> order detail + items (used for the receipt / order tracking page)
require '../../includes/auth_check.php';
require '../../config/db.php';
require_login();
$stmt = $pdo->prepare("SELECT * FROM orders WHERE order_id = ?");
$stmt->execute([$_GET['id']]);
$order = $stmt->fetch();
if (!$order || ($_SESSION['role'] !== 'admin' && (int)$order['user_id'] !== (int)$_SESSION['user_id'])) {
    http_response_code(404);
    echo json_encode(["error" => "Order not found"]);
    exit;
}
$items = $pdo->prepare("SELECT * FROM order_items WHERE order_id = ?");
$items->execute([$_GET['id']]);
$order['items'] = $items->fetchAll();
echo json_encode($order);
