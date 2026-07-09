<?php
// POST { email, password } -> sets session, returns user + role
require '../../config/db.php';
require '../../config/config.php';
require '../../includes/functions.php';
$data = json_decode(file_get_contents("php://input"), true);
$email = trim($data['email'] ?? '');
$password = $data['password'] ?? '';
if (!is_valid_email($email)) {
    http_response_code(422);
    echo json_encode(["error" => "Enter a valid email address"]);
    exit;
}
$stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
$stmt->execute([$email]);
$user = $stmt->fetch();
if ($user && password_verify($password, $user['password_hash'])) {
    $_SESSION['user_id'] = $user['user_id'];
    $_SESSION['role'] = $user['role'];
    unset($user['password_hash']);
    echo json_encode(["success" => true, "user" => $user]);
} else {
    http_response_code(401);
    echo json_encode(["error" => "Invalid email or password"]);
}
