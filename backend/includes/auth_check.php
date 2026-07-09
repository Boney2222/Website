<?php
// Include at the top of any protected endpoint.
// Usage: require '../../includes/auth_check.php'; then optionally require_admin();
require_once __DIR__ . '/../config/config.php';

function require_login() {
    if (!isset($_SESSION['user_id'])) {
        http_response_code(401);
        echo json_encode(["error" => "Not logged in"]);
        exit;
    }
}

function require_admin() {
    require_login();
    if ($_SESSION['role'] !== 'admin') {
        http_response_code(403);
        echo json_encode(["error" => "Admin access only"]);
        exit;
    }
}
