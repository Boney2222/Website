<?php
// GET -> current user's cart with product details + line totals
require '../../includes/auth_check.php';
require '../../config/db.php';
require_login();
$stmt = $pdo->prepare("SELECT ci.*, p.name, p.price, p.image_url, v.variation_value, v.price_delta
                        FROM cart_items ci
                        JOIN products p ON ci.product_id = p.product_id
                        LEFT JOIN product_variations v ON ci.variation_id = v.variation_id
                        WHERE ci.user_id = ?");
$stmt->execute([$_SESSION['user_id']]);
echo json_encode($stmt->fetchAll());
