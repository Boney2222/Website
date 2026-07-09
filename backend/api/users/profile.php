<?php
// GET -> current user's profile info
require '../../includes/auth_check.php';
require '../../config/db.php';
require_login();
$stmt = $pdo->prepare("SELECT user_id, full_name, email, phone, profile_image, role FROM users WHERE user_id = ?");
$stmt->execute([$_SESSION['user_id']]);
echo json_encode($stmt->fetch());
