<?php
// PUT { full_name, phone, password (optional) }
require '../../includes/auth_check.php';
require '../../config/db.php';
require '../../includes/functions.php';
require_login();
$data = json_decode(file_get_contents("php://input"), true);
$name = trim($data['full_name'] ?? '');
$phone = trim($data['phone'] ?? '');
if ($name === '') {
    http_response_code(422);
    echo json_encode(["error" => "Name is required"]);
    exit;
}
if ($phone !== '' && !is_valid_phone($phone)) {
    http_response_code(422);
    echo json_encode(["error" => "Enter a valid phone number"]);
    exit;
}
if (!empty($data['password'])) {
    if (strlen($data['password']) < 8) {
        http_response_code(422);
        echo json_encode(["error" => "Password must be at least 8 characters"]);
        exit;
    }
    $hash = password_hash($data['password'], PASSWORD_DEFAULT);
    $pdo->prepare("UPDATE users SET full_name=?, phone=?, password_hash=? WHERE user_id=?")
        ->execute([$name, $phone !== '' ? $phone : null, $hash, $_SESSION['user_id']]);
} else {
    $pdo->prepare("UPDATE users SET full_name=?, phone=? WHERE user_id=?")
        ->execute([$name, $phone !== '' ? $phone : null, $_SESSION['user_id']]);
}
echo json_encode(["success" => true]);
