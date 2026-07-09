<?php
// GET -> list wishlist items | POST { product_id } -> add | DELETE ?id=product_id -> remove
require '../../includes/auth_check.php';
require '../../config/db.php';
require_login();
$method = $_SERVER['REQUEST_METHOD'];
if ($method === 'GET') {
    $stmt = $pdo->prepare("SELECT w.*, p.name, p.price, p.image_url FROM wishlist w JOIN products p ON w.product_id = p.product_id WHERE w.user_id=?");
    $stmt->execute([$_SESSION['user_id']]);
    echo json_encode($stmt->fetchAll());
} elseif ($method === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    $pdo->prepare("INSERT INTO wishlist (user_id, product_id) VALUES (?, ?)")->execute([$_SESSION['user_id'], $data['product_id']]);
    echo json_encode(["success" => true]);
} elseif ($method === 'DELETE') {
    $pdo->prepare("DELETE FROM wishlist WHERE user_id=? AND product_id=?")->execute([$_SESSION['user_id'], $_GET['id']]);
    echo json_encode(["success" => true]);
}
