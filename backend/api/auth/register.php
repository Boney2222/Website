<?php
// POST { full_name, email, password, phone }
// Creates a new customer account (role = 'customer' by default).
require '../../config/db.php';
require '../../config/config.php';
require '../../includes/functions.php';
$data = json_decode(file_get_contents("php://input"), true);
$name = trim($data['full_name'] ?? '');
$email = trim($data['email'] ?? '');
$password = $data['password'] ?? '';
$phone = trim($data['phone'] ?? '');

if ($name === '' || $email === '' || $password === '') {
    http_response_code(422);
    echo json_encode(["error" => "Name, email, and password are required"]);
    exit;
}
if (!is_valid_email($email)) {
    http_response_code(422);
    echo json_encode(["error" => "Enter a valid email address"]);
    exit;
}
if ($phone !== '' && !is_valid_phone($phone)) {
    http_response_code(422);
    echo json_encode(["error" => "Enter a valid phone number"]);
    exit;
}
if (strlen($password) < 8) {
    http_response_code(422);
    echo json_encode(["error" => "Password must be at least 8 characters"]);
    exit;
}

try {
    $hash = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $pdo->prepare("INSERT INTO users (full_name, email, password_hash, phone) VALUES (?, ?, ?, ?)");
    $stmt->execute([$name, $email, $hash, $phone !== '' ? $phone : null]);
    $_SESSION['user_id'] = $pdo->lastInsertId();
    $_SESSION['role'] = 'customer';
    echo json_encode([
        "success" => true,
        "user" => [
            "user_id" => $_SESSION['user_id'],
            "full_name" => $name,
            "email" => $email,
            "phone" => $phone !== '' ? $phone : null,
            "role" => "customer"
        ]
    ]);
} catch (PDOException $e) {
    http_response_code(409);
    echo json_encode(["error" => "That email is already registered"]);
}
