<?php
// DELETE ?id=cart_item_id
require '../../includes/auth_check.php';
require '../../config/db.php';
require_login();
$stmt = $pdo->prepare("DELETE FROM cart_items WHERE cart_item_id=? AND user_id=?");
$stmt->execute([$_GET['id'], $_SESSION['user_id']]);
echo json_encode(["success" => true]);
