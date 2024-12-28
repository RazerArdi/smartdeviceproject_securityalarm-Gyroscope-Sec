<?php
require 'vendor/autoload.php';

use Kreait\Firebase\Factory;

// Konfigurasi Firebase
$firebase = (new Factory)
    ->withServiceAccount(__DIR__ . '/path-to-your-service-account-key.json') // Ganti dengan file kunci JSON Anda
    ->withDatabaseUri('https://PIRANTI.firebaseio.com/'); // Ganti dengan URL database Firebase Anda

$database = $firebase->createDatabase();
$storage = $firebase->createStorage();
$bucket = $storage->getBucket();

// Tangkap endpoint yang diakses
$method = $_SERVER['REQUEST_METHOD'];
$endpoint = $_GET['endpoint'] ?? '';
$id = $_GET['id'] ?? null;

// Fungsi: GET semua data
if ($method === 'GET' && $endpoint === 'get_all_logs') {
    $logsRef = $database->getReference('logs');
    $logs = $logsRef->getValue();

    if ($logs) {
        echo json_encode($logs);
    } else {
        echo json_encode(["message" => "No data found"]);
    }
}

// Fungsi: GET berdasarkan ID
elseif ($method === 'GET' && $endpoint === 'get_log_by_id' && $id) {
    $logRef = $database->getReference('logs/' . $id);
    $log = $logRef->getValue();

    if ($log) {
        echo json_encode($log);
    } else {
        echo json_encode(["message" => "No data found for ID $id"]);
    }
}

// Fungsi: DELETE berdasarkan ID
elseif ($method === 'DELETE' && $endpoint === 'delete_log' && $id) {
    $logRef = $database->getReference('logs/' . $id);
    $log = $logRef->getValue();

    if ($log && isset($log['image_path'])) {
        // Hapus gambar dari Firebase Storage
        $bucket->object($log['image_path'])->delete();
    }

    $logRef->remove();
    echo json_encode(["message" => "Data with ID $id has been deleted."]);
}

// Fungsi: Tambah data baru
elseif ($method === 'POST' && $endpoint === 'add_log') {
    $state = $_POST['state'] ?? '';
    $message = $_POST['message'] ?? '';
    $imagePath = null;

    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $imageName = uniqid() . '-' . basename($_FILES['image']['name']);
        $tempFile = $_FILES['image']['tmp_name'];

        $file = fopen($tempFile, 'r');
        $object = $bucket->upload($file, [
            'name' => "images/{$imageName}",
            'metadata' => ['contentType' => $_FILES['image']['type']],
        ]);
        fclose($file);

        $imagePath = $object->info()['name'];
    }

    $newLog = [
        'state' => $state,
        'message' => $message,
        'image_path' => $imagePath,
    ];

    $logsRef = $database->getReference('logs');
    $logsRef->push($newLog);

    echo json_encode(["message" => "Data uploaded successfully.", "image_path" => $imagePath]);
}

// Jika endpoint tidak ditemukan
else {
    echo json_encode(["message" => "Invalid endpoint or request method."]);
}
?>
