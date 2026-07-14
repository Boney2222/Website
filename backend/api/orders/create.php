<?php
// POST { delivery_method, address_id, payment_method, items:[...] }
// Creates order + order_items from the user's cart, then clears the cart.
require '../../includes/auth_check.php';
require '../../config/db.php';
require '../../includes/functions.php';
require_login();
$data = json_decode(file_get_contents("php://input"), true);

if (!in_array($data['delivery_method'] ?? '', ['pickup', 'delivery'], true)) {
    http_response_code(422);
    echo json_encode(["error" => "Choose a valid delivery method"]);
    exit;
}
$pickup_date = null;
$pickup_time = null;
if (($data['delivery_method'] ?? '') === 'pickup') {
    $pickup_date = trim((string)($data['pickup_date'] ?? ''));
    $pickup_time = trim((string)($data['pickup_time'] ?? ''));
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $pickup_date) || !preg_match('/^\d{2}:\d{2}$/', $pickup_time)) {
        http_response_code(422);
        echo json_encode(["error" => "Choose a pickup date and time"]);
        exit;
    }
    $tz = new DateTimeZone('Asia/Yangon');
    $pickupAt = DateTime::createFromFormat('Y-m-d H:i', "{$pickup_date} {$pickup_time}", $tz);
    $now = new DateTime('now', $tz);
    $latestDate = (clone $now)->modify('+14 days')->setTime(23, 59, 59);
    $weekday = $pickupAt ? (int)$pickupAt->format('N') : 0;
    $hourMinute = $pickupAt ? $pickupAt->format('H:i') : '';
    $minute = $pickupAt ? (int)$pickupAt->format('i') : -1;

    if (!$pickupAt || $pickupAt < (clone $now)->modify('+30 minutes')) {
        http_response_code(422);
        echo json_encode(["error" => "Choose a future pickup time"]);
        exit;
    }
    if ($pickupAt > $latestDate) {
        http_response_code(422);
        echo json_encode(["error" => "Pickup is available only within the next 14 days"]);
        exit;
    }
    if ($weekday === 7) {
        http_response_code(422);
        echo json_encode(["error" => "Pickup is not available on Sundays"]);
        exit;
    }
    if ($hourMinute < '10:00' || $hourMinute > '18:30' || !in_array($minute, [0, 30], true)) {
        http_response_code(422);
        echo json_encode(["error" => "Pickup time must be Monday-Saturday, 10:00 AM-6:30 PM, in 30-minute slots"]);
        exit;
    }
}
$payment_method = $data['payment_method'] ?? '';
if (!in_array($payment_method, ['cod', 'card'], true)) {
    http_response_code(422);
    echo json_encode(["error" => "Choose cash on delivery or card payment"]);
    exit;
}
if ($payment_method === 'card') {
    $card = $data['card'] ?? [];
    $last4 = preg_replace('/\D+/', '', (string)($card['last4'] ?? ''));
    $expiry_month = (int)($card['expiry_month'] ?? 0);
    $expiry_year = (int)($card['expiry_year'] ?? 0);
    if (trim((string)($card['cardholder_name'] ?? '')) === '' || !preg_match('/^\d{4}$/', $last4) || $expiry_month < 1 || $expiry_month > 12 || $expiry_year < (int)date('Y')) {
        http_response_code(422);
        echo json_encode(["error" => "Enter valid card details"]);
        exit;
    }
}
if (empty($data['items']) || !is_array($data['items'])) {
    http_response_code(422);
    echo json_encode(["error" => "Your cart is empty"]);
    exit;
}

try {
    $pdo->beginTransaction();

    $subtotal = 0;
    $checkedItems = [];
    $productStmt = $pdo->prepare("SELECT product_id, name, price, stock_qty FROM products WHERE product_id = ? AND is_active = 1 FOR UPDATE");

    foreach ($data['items'] as $i) {
        $product_id = (int)($i['product_id'] ?? 0);
        $quantity = max(1, (int)($i['quantity'] ?? 0));
        $productStmt->execute([$product_id]);
        $product = $productStmt->fetch();
        if (!$product) {
            throw new RuntimeException("A product in your cart is no longer available");
        }
        if ($quantity > (int)$product['stock_qty']) {
            throw new RuntimeException("Only {$product['stock_qty']} item(s) available for {$product['name']}");
        }
        $unit_price = (float)$product['price'];
        $line_total = $unit_price * $quantity;
        $subtotal += $line_total;
        $checkedItems[] = [
            "product_id" => $product_id,
            "variation_label" => $i['variation_label'] ?? null,
            "name" => $product['name'],
            "unit_price" => $unit_price,
            "quantity" => $quantity,
            "line_total" => $line_total
        ];
    }

    $delivery_fee = $data['delivery_method'] === 'delivery' ? 5000.00 : 0.00;
    $total = $subtotal + $delivery_fee;
    $order_code = generate_order_code();

    $stmt = $pdo->prepare("INSERT INTO orders (order_code, user_id, delivery_method, pickup_date, pickup_time, address_id, payment_method, subtotal, delivery_fee, total)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$order_code, $_SESSION['user_id'], $data['delivery_method'], $pickup_date ?: null, $pickup_time ?: null, $data['address_id'] ?? null, $payment_method, $subtotal, $delivery_fee, $total]);
    $order_id = $pdo->lastInsertId();

    if ($payment_method === 'card' && ($data['save_card'] ?? true)) {
        $card = $data['card'];
        $brand = preg_replace('/[^a-zA-Z0-9 ]+/', '', (string)($card['brand'] ?? 'Card')) ?: 'Card';
        $cardStmt = $pdo->prepare("INSERT INTO payment_cards (user_id, cardholder_name, brand, last4, expiry_month, expiry_year, is_default)
                                    VALUES (?, ?, ?, ?, ?, ?, 1)");
        $cardStmt->execute([
            $_SESSION['user_id'],
            trim((string)$card['cardholder_name']),
            $brand,
            preg_replace('/\D+/', '', (string)$card['last4']),
            (int)$card['expiry_month'],
            (int)$card['expiry_year']
        ]);
    }

    $item_stmt = $pdo->prepare("INSERT INTO order_items (order_id, product_id, variation_label, product_name, unit_price, quantity, line_total)
                                 VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stock_stmt = $pdo->prepare("UPDATE products SET stock_qty = stock_qty - ? WHERE product_id = ?");
    foreach ($checkedItems as $i) {
        $item_stmt->execute([$order_id, $i['product_id'], $i['variation_label'], $i['name'], $i['unit_price'], $i['quantity'], $i['line_total']]);
        $stock_stmt->execute([$i['quantity'], $i['product_id']]);
    }
    $pdo->prepare("DELETE FROM cart_items WHERE user_id = ?")->execute([$_SESSION['user_id']]);

    log_action($pdo, $_SESSION['user_id'], "Created order {$order_code} ({$data['delivery_method']}, {$payment_method}, total {$total})");
    $pdo->commit();
    echo json_encode(["success" => true, "order_id" => $order_id, "order_code" => $order_code]);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(422);
    echo json_encode(["error" => $e->getMessage()]);
}
