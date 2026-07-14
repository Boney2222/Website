<?php
require '../../config/db.php';
require '../../config/config.php';
require '../../includes/functions.php';
if (isset($_SESSION['user_id'])) {
    log_action($pdo, $_SESSION['user_id'], "Logged out");
}
session_destroy();
echo json_encode(["success" => true]);
