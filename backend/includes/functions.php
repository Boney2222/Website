<?php
// Shared helper functions
function generate_order_code() {
    return "PP-" . date("Ymd") . "-" . strtoupper(substr(uniqid(), -5));
}

function log_action($pdo, $user_id, $action) {
    $stmt = $pdo->prepare("INSERT INTO activity_logs (user_id, action, ip_address) VALUES (?, ?, ?)");
    $stmt->execute([$user_id, $action, $_SERVER['REMOTE_ADDR'] ?? '']);
}

function is_valid_email($email) {
    return is_string($email) && filter_var($email, FILTER_VALIDATE_EMAIL);
}

function normalize_phone($phone) {
    return preg_replace('/[\s().-]+/', '', trim((string)$phone));
}

function is_valid_phone($phone) {
    $normalized = normalize_phone($phone);
    return (bool) preg_match('/^\+?[0-9]{7,15}$/', $normalized);
}
