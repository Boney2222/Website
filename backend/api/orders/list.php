<?php
// GET -> order history for logged-in user (or all orders if admin, via ?all=1)
require '../../includes/auth_check.php';
require '../../config/db.php';
require_login();
if (!empty($_GET['all']) && $_SESSION['role'] === 'admin') {
    echo json_encode($pdo->query("SELECT o.*, u.full_name, u.email,
        (SELECT COUNT(*) FROM order_items oi WHERE oi.order_id = o.order_id) AS item_count
        FROM orders o
        JOIN users u ON u.user_id = o.user_id
        ORDER BY o.created_at DESC")->fetchAll());
} else {
    $stmt = $pdo->prepare("SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC");
    $stmt->execute([$_SESSION['user_id']]);
    echo json_encode($stmt->fetchAll());
}
