<?php
// GET (admin only) -> dashboard totals: revenue, order count, low-stock products
require '../../includes/auth_check.php';
require '../../config/db.php';
require_admin();
$stats = [
    "total_orders" => $pdo->query("SELECT COUNT(*) FROM orders")->fetchColumn(),
    "total_revenue" => $pdo->query("SELECT SUM(total) FROM orders WHERE status != 'cancelled'")->fetchColumn(),
    "low_stock" => $pdo->query("SELECT product_id, name, stock_qty FROM products WHERE stock_qty <= 5")->fetchAll(),
];
echo json_encode($stats);
