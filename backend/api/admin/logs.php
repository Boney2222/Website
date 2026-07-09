<?php
// GET (admin only) -> recent activity/security logs
require '../../includes/auth_check.php';
require '../../config/db.php';
require_admin();
$stmt = $pdo->query("
    SELECT
        l.log_id,
        l.user_id,
        l.action,
        l.ip_address,
        l.created_at,
        COALESCE(u.full_name, 'Unknown admin') AS full_name
    FROM activity_logs l
    LEFT JOIN users u ON l.user_id = u.user_id
    ORDER BY l.created_at DESC, l.log_id DESC
    LIMIT 100
");
echo json_encode($stmt->fetchAll());
