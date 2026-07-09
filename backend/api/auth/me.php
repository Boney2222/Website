<?php
require '../../includes/auth_check.php';
require '../../config/db.php';
require_login();

$stmt = $pdo->prepare("SELECT user_id, full_name, email, phone, role, profile_image, created_at FROM users WHERE user_id = ?");
$stmt->execute([$_SESSION['user_id']]);
echo json_encode(["success" => true, "user" => $stmt->fetch()]);
