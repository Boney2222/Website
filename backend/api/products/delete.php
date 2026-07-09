<?php
// DELETE (admin only) ?id=123 -> soft delete (is_active = 0)
require '../../includes/auth_check.php';
require '../../config/db.php';
require '../../includes/functions.php';
require_admin();
$nameStmt = $pdo->prepare("SELECT name FROM products WHERE product_id = ?");
$nameStmt->execute([$_GET['id']]);
$name = $nameStmt->fetchColumn() ?: "ID {$_GET['id']}";
$stmt = $pdo->prepare("UPDATE products SET is_active = 0 WHERE product_id = ?");
$stmt->execute([$_GET['id']]);
log_action($pdo, $_SESSION['user_id'], "Removed product {$name}");
echo json_encode(["success" => true]);
