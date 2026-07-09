<?php
// PUT (admin only) { order_id, status }
require '../../includes/auth_check.php';
require '../../config/db.php';
require '../../includes/functions.php';
require_admin();
$data = json_decode(file_get_contents("php://input"), true);
$stmt = $pdo->prepare("UPDATE orders SET status=? WHERE order_id=?");
$stmt->execute([$data['status'], $data['order_id']]);
log_action($pdo, $_SESSION['user_id'], "Updated order #{$data['order_id']} status to {$data['status']}");
echo json_encode(["success" => true]);
