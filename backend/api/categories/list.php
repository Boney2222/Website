<?php
require '../../config/db.php';
require '../../config/config.php';
echo json_encode($pdo->query("SELECT * FROM categories")->fetchAll());
