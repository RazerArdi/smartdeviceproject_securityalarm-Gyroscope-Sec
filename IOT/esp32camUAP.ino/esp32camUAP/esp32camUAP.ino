#include <Wire.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include "esp_camera.h"
#include "FS.h"
#include "SPIFFS.h"
#include "base64.h"
#include <string.h>
#include "esp_task_wdt.h"
#include <HTTPClient.h>

// Firebase Configuration (Dummy, example)
#define API_KEY "AIzaSyBffZ8HnCzISN4Ahxt0wYKTyevtivvaIK4(Dummy, example)"
#define DATABASE_URL "https://pirantidsa-e8cda-default-rtdb.asia-southeast2.firebasedatabase.app/"
#define STORAGE_BUCKET_ID "piranti-e8cda.appspot.com"
#define USER_EMAIL "bayuardi30@outlook.com"
#define USER_PASSWORD "testing"

// WiFi credentials
const char* ssid = "TEST";
const char* password = "12345678";

// Camera configuration
#define CAMERA_MODEL_AI_THINKER
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

#define STORAGE_BUCKET_URL "https://firebasestorage.googleapis.com/v0/b/piranti-e8cda.firebasestorage.app"
String idToken = "";  // Will be generated during authentication


// Global Firebase objects
FirebaseData fbdo;
FirebaseData fbdoStream;
FirebaseAuth auth;
FirebaseConfig fbConfig;

// Initialize system states
volatile char lastLedStatus[10] = ""; // Use char array instead of volatile String
volatile bool isCapturing = false;

void setupCamera() {
    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer = LEDC_TIMER_0;
    config.pin_d0 = Y2_GPIO_NUM;
    config.pin_d1 = Y3_GPIO_NUM;
    config.pin_d2 = Y4_GPIO_NUM;
    config.pin_d3 = Y5_GPIO_NUM;
    config.pin_d4 = Y6_GPIO_NUM;
    config.pin_d5 = Y7_GPIO_NUM;
    config.pin_d6 = Y8_GPIO_NUM;
    config.pin_d7 = Y9_GPIO_NUM;
    config.pin_xclk = XCLK_GPIO_NUM;
    config.pin_pclk = PCLK_GPIO_NUM;
    config.pin_vsync = VSYNC_GPIO_NUM;
    config.pin_href = HREF_GPIO_NUM;
    config.pin_sscb_sda = SIOD_GPIO_NUM;
    config.pin_sscb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn = PWDN_GPIO_NUM;
    config.pin_reset = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000;
    config.pixel_format = PIXFORMAT_JPEG;
    config.frame_size = FRAMESIZE_QQVGA;  // Reduce frame size to 160x120
    config.jpeg_quality = 20;  // Lower quality for smaller payload
    config.fb_count = 2;       // Minimal buffer count for stability

    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("Camera init failed with error 0x%x", err);
        return;
    }
}

void uploadImageToFirebaseStorage(camera_fb_t *fb) {
    if (!fb) {
        Serial.println("Camera capture failed");
        return;
    }

    Serial.printf("Free heap before upload: %d\n", ESP.getFreeHeap());

    if (Firebase.ready()) {
        String path = String("images/") + String(millis()) + String(".jpg");
        String url = String(STORAGE_BUCKET_URL) + String("/") + path + String("?alt=media&token=") + idToken;

        HTTPClient http;
        http.begin(url);
        http.addHeader("Content-Type", "image/jpeg");
        int httpCode = http.PUT(fb->buf, fb->len);

        if (httpCode > 0) {
            if (httpCode == HTTP_CODE_OK || httpCode == HTTP_CODE_CREATED) {
                Serial.println("Image uploaded to storage successfully");

                // Get the download URL
                String downloadUrl = http.getString();

                // Store the download URL in the Realtime Database
                FirebaseJson json;
                json.set("imageUrl", downloadUrl);
                json.set("timestamp/.sv", "timestamp");

                if (Firebase.setJSON(fbdo, "/image_data", json)) {
                    Serial.println("Image URL stored in database successfully");
                    Firebase.setString(fbdo, "/led_status", "OFF"); // Reset led_status to OFF
                } else {
                    Serial.println("Failed to store image URL in database: " + String(fbdo.errorReason()));
                }
            } else {
                Serial.println("Failed to upload image to storage: " + http.errorToString(httpCode));
            }
        } else {
            Serial.println("Failed to connect to storage: " + http.errorToString(httpCode));
        }
        http.end();
    }

    Serial.printf("Free heap after upload: %d\n", ESP.getFreeHeap());
}


bool connectWiFi() {
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);

    unsigned long startAttempt = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - startAttempt < 30000) {  // Timeout setelah 30 detik
        delay(500);
        Serial.print(".");
    }

    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("\nWiFi connection failed!");
        return false;
    }

    Serial.println("\nWiFi connected");
    return true;
}

void captureAndUpload() {
    if (!isCapturing) {
        isCapturing = true;
        camera_fb_t *fb = esp_camera_fb_get();
        if (fb) {
            uploadImageToFirebaseStorage(fb);
            esp_camera_fb_return(fb);
        }
        isCapturing = false;
    }
}

// Stream callback function
void streamCallback(StreamData data) {
    String path = data.dataPath();
    String value = data.stringData();

    Serial.println("Stream Data Path: " + path);
    Serial.println("Stream Data Value: " + value);

    if (value == "CAPTURE" && strcmp((const char*)lastLedStatus, value.c_str()) != 0) {
        strcpy((char*)lastLedStatus, value.c_str());
        Serial.println("Triggering capture and upload.");
        captureAndUpload();
    }
}

void streamTimeoutCallback(bool timeout) {
    if (timeout) {
        Serial.println("Stream timeout, resuming...");
        if (!Firebase.beginStream(fbdoStream, "/led_status")) {
            Serial.println("Could not resume stream");
        }
    }
}

bool initFirebase() {
    fbConfig.api_key = API_KEY;
    fbConfig.database_url = DATABASE_URL;

    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;

    fbConfig.token_status_callback = tokenStatusCallback;

    Firebase.begin(&fbConfig, &auth);
    Firebase.reconnectWiFi(true);

    if (!Firebase.beginStream(fbdoStream, "/led_status")) {
        Serial.println("Could not begin stream");
        Serial.println(fbdoStream.errorReason());
        return false;
    }

    Firebase.setStreamCallback(fbdoStream, streamCallback, streamTimeoutCallback);
    Serial.println("Stream callback set");
    return true;
}

void setup() {
    Serial.begin(115200);
    Serial.println("Entering setup");
    Serial.printf("Free heap at start: %d\n", ESP.getFreeHeap());

    if (!connectWiFi()) {
        Serial.println("WiFi connection failed");
        while (true); // Halt execution
    } else {
        Serial.println("WiFi connected");
    }

    Serial.printf("Free heap after WiFi: %d\n", ESP.getFreeHeap());
    Serial.println("Initializing Firebase");
    if (!initFirebase()) {
        Serial.println("Firebase initialization failed");
        while (true); // Halt execution
    } else {
        Serial.println("Firebase initialized");
    }

    Serial.printf("Free heap after Firebase: %d\n", ESP.getFreeHeap());
    setupCamera();
    Serial.println("Camera initialized");
    Serial.printf("Free heap after camera setup: %d\n", ESP.getFreeHeap());
}

void loop() {

    // Cek koneksi Wi-Fi
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi connection lost. Reconnecting...");
        connectWiFi();
    }

    // Cek status Firebase
    if (!Firebase.ready()) {
        Serial.println("Firebase connection lost. Reinitializing...");
        initFirebase();
    }

    delay(100);  // Tambahkan delay agar loop tidak terlalu cepat dan tidak menyebabkan masalah dengan watchdog
}
