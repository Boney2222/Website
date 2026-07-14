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
$logs = $stmt->fetchAll();

if (isset($_GET['download']) && $_GET['download'] === 'csv') {
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="admin-security-logs-' . date('Ymd-His') . '.csv"');
    $out = fopen('php://output', 'w');
    fputcsv($out, ['Log ID', 'Admin', 'Action', 'IP Address', 'Created At']);
    foreach ($logs as $log) {
        fputcsv($out, [$log['log_id'], $log['full_name'], $log['action'], $log['ip_address'], $log['created_at']]);
    }
    fclose($out);
    exit;
}

echo json_encode($logs);
