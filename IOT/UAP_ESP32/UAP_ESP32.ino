#include <Wire.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// Firebase Configuration (Dummy, example)
#define API_KEY "AIzaSyBffZ8HnCzISN4Ahxt0wYKTyevtivvaIK4SS"
#define DATABASE_URL "https://pirantidas-e8cda-default-rtdb.asia-southeast2.firebasedatabase.app/"
#define USER_EMAIL "bayuardi30@outlook.com" 
#define USER_PASSWORD "testing" 

// WiFi credentials
const char* ssid = "TEST";
const char* password = "12345678";

// Pin definitions
#define RED_LED 25      // Pin untuk LED merah
#define YELLOW_LED 26   // Pin untuk LED kuning
#define GREEN_LED 27    // Pin untuk LED hijau
#define BUZZER 33      // Pin untuk buzzer
#define MPU_ADDR 0x68   // Alamat I2C MPU6050

// Thresholds and timing constants
#define DANGER_THRESHOLD 50
#define WARNING_THRESHOLD 25
#define WIFI_TIMEOUT 20000        // 20 detik timeout untuk koneksi WiFi
#define FIREBASE_RETRY_DELAY 5000 // 5 detik antara percobaan Firebase

unsigned long lastSyncTime = 0;
#define SYNC_INTERVAL 5000 // Interval pembacaan Firebase dalam milidetik (5 detik)


// Global variables
bool systemActive = false;
float angleX, angleY;
String lastStatus = "IDLE";
unsigned long lastFirebaseRetry = 0;
bool firebaseInitialized = false;

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Function declarations
void initMPU();
bool connectWiFi();
bool initFirebase();
void setSystemState(bool active);
void readMPU(float &x, float &y);
void updateFirebase(const char* status);

void setup() {
    Serial.begin(115200);
    
    // Initialize pins
    pinMode(RED_LED, OUTPUT);
    pinMode(YELLOW_LED, OUTPUT);
    pinMode(GREEN_LED, OUTPUT);
    pinMode(BUZZER, OUTPUT);
    
    // Turn off all outputs initially
    digitalWrite(RED_LED, LOW);
    digitalWrite(YELLOW_LED, LOW);
    digitalWrite(GREEN_LED, LOW);
    digitalWrite(BUZZER, LOW);
    
    // Initialize I2C
    Wire.begin(21, 22);
    initMPU();
    
    // Connect to WiFi and initialize Firebase
    if (connectWiFi()) {
        firebaseInitialized = initFirebase();
    }
    
    Serial.println("ESP32 initialization complete.");
}

void initMPU() {
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x6B);  // PWR_MGMT_1 register
    Wire.write(0);     // wake up MPU-6050
    if (Wire.endTransmission(true) != 0) {
        Serial.println("Failed to initialize MPU6050!");
        digitalWrite(RED_LED, HIGH);  // Indicate sensor error
        delay(1000);
        ESP.restart();  // Restart if sensor initialization fails
    }
    Serial.println("MPU6050 initialized successfully");
}

bool connectWiFi() {
    Serial.print("Connecting to WiFi");
    WiFi.begin(ssid, password);
    
    unsigned long startAttempt = millis();
    while (WiFi.status() != WL_CONNECTED) {
        if (millis() - startAttempt > WIFI_TIMEOUT) {
            Serial.println("\nWiFi connection timeout!");
            return false;
        }
        delay(500);
        Serial.print(".");
    }
    
    Serial.println("\nWiFi connected");
    Serial.println("IP address: " + WiFi.localIP().toString());
    return true;
}

bool initFirebase() {
    config.api_key = API_KEY;
    config.database_url = DATABASE_URL;
    
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;
    
    config.token_status_callback = tokenStatusCallback;
    
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
    
    Serial.println("Waiting for Firebase authentication...");
    unsigned long startAuth = millis();
    while (millis() - startAuth < 10000) {  // 10 second timeout
        if (Firebase.ready()) {
            Serial.println("Firebase authenticated!");
            if (Firebase.setString(fbdo, "/status", "SYSTEM_STARTUP")) { // Use `fbdo` by value
                Serial.println("Firebase connection verified");
                return true;
            } else {
                Serial.println("Firebase test write failed: " + fbdo.errorReason());
            }
            break;
        }
        delay(100);
    }
    
    Serial.println("Firebase initialization failed");
    return false;
}

void syncSystemState() {
    if (!firebaseInitialized) {
        return; // Jangan lanjutkan jika Firebase belum diinisialisasi
    }

    // Baca status dari key "/SISTEM"
    if (Firebase.getString(fbdo, "/SISTEM")) {
        String firebaseStatus = fbdo.stringData();
        Serial.println("Firebase SISTEM status: " + firebaseStatus);

        // Sesuaikan status sistem ESP32 berdasarkan nilai di Firebase
        if (firebaseStatus == "SYSTEM_ACTIVATED" && !systemActive) {
            setSystemState(true);
        } else if (firebaseStatus == "SYSTEM_DEACTIVATED" && systemActive) {
            setSystemState(false);
        }
    } else {
        Serial.println("Failed to read SISTEM key: " + fbdo.errorReason());
    }
}


void setSystemState(bool active) {
    systemActive = active;
    digitalWrite(GREEN_LED, !active);  // Green LED on when system is inactive
    digitalWrite(YELLOW_LED, LOW);
    digitalWrite(RED_LED, LOW);
    digitalWrite(BUZZER, LOW);
    
    if (systemActive) {
        Serial.println("System Activated");
        updateFirebase("SYSTEM_ACTIVATED");
    } else {
        Serial.println("System Deactivated");
        updateFirebase("SYSTEM_DEACTIVATED");
    }
}


void readMPU(float &x, float &y) {
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x3B);
    if (Wire.endTransmission(false) != 0) {
        Serial.println("Error reading from MPU6050");
        return;
    }
    
    if (Wire.requestFrom(MPU_ADDR, 6, true) != 6) {
        Serial.println("Failed to read 6 bytes from MPU6050");
        return;
    }
    
    int16_t AcX = Wire.read() << 8 | Wire.read();
    int16_t AcY = Wire.read() << 8 | Wire.read();
    int16_t AcZ = Wire.read() << 8 | Wire.read();
    
    x = atan2(AcY, sqrt(pow(AcX, 2) + pow(AcZ, 2))) * 180 / PI;
    y = atan2(-AcX, sqrt(pow(AcY, 2) + pow(AcZ, 2))) * 180 / PI;
}

void updateFirebase(const char* status) {
    if (!firebaseInitialized || lastStatus == status) {
        return;
    }

    // Cek koneksi WiFi
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi disconnected. Attempting to reconnect...");
        if (!connectWiFi()) {
            return;
        }
    }

    // Ambil waktu saat ini
    unsigned long currentMillis = millis();
    String timeStamp = String(currentMillis);

    // Jika status adalah "SYSTEM_ACTIVATED" atau "SYSTEM_DEACTIVATED", simpan ke key "SISTEM"
    if (strcmp(status, "SYSTEM_ACTIVATED") == 0 || strcmp(status, "SYSTEM_DEACTIVATED") == 0) {
        if (Firebase.setString(fbdo, "/SISTEM", status)) {
            Serial.println("Firebase SYSTEM key updated: " + String(status));
        } else {
            Serial.println("Failed to update SYSTEM key: " + fbdo.errorReason());
        }
    } else {
        // Simpan status operasional ke key "status"
        if (Firebase.setString(fbdo, "/status", status)) {
            Serial.println("Firebase status key updated: " + String(status));

            // Update data tambahan ke Firebase
            Firebase.setString(fbdo, "/timestamp", timeStamp);  // Kirim timestamp
            Firebase.setFloat(fbdo, "/mpu/angleX", angleX);    // Kirim nilai angle X dari MPU6050
            Firebase.setFloat(fbdo, "/mpu/angleY", angleY);    // Kirim nilai angle Y dari MPU6050

            // Status LED dan alarm
            String ledStatus = systemActive ? "ACTIVE" : "IDLE";
            Firebase.setString(fbdo, "/led_status", ledStatus);
            Firebase.setBool(fbdo, "/buzzer", digitalRead(BUZZER));

            lastStatus = status;
        } else {
            Serial.println("Failed to update status key: " + fbdo.errorReason());
        }
    }
}



void loop() {
    readMPU(angleX, angleY);  // Membaca nilai angle dari MPU6050
    
    // Sinkronisasi status dengan Firebase setiap 5 detik
    if (millis() - lastSyncTime >= SYNC_INTERVAL) {
        syncSystemState();
        lastSyncTime = millis();
    }

    if (systemActive) {
        // Deteksi bahaya atau peringatan berdasarkan nilai sensor
        if (abs(angleX) > DANGER_THRESHOLD || abs(angleY) > DANGER_THRESHOLD) {
            digitalWrite(RED_LED, HIGH); // LED merah menyala
            digitalWrite(YELLOW_LED, LOW);
            digitalWrite(BUZZER, HIGH); // Buzzer menyala
            Serial.println("DANGER: Motion detected");
            updateFirebase("CAPTURE");  // Kirim status "CAPTURE" ke Firebase
        } else if (abs(angleX) > WARNING_THRESHOLD || abs(angleY) > WARNING_THRESHOLD) {
            digitalWrite(YELLOW_LED, HIGH); // LED kuning menyala
            digitalWrite(RED_LED, LOW);
            digitalWrite(BUZZER, LOW); // Buzzer mati
            Serial.println("WARNING: Slight motion detected");
            updateFirebase("WARNING"); // Kirim status "WARNING" ke Firebase
        } else {
            digitalWrite(YELLOW_LED, LOW); // LED kuning mati
            digitalWrite(RED_LED, LOW); // LED merah mati
            digitalWrite(BUZZER, LOW); // Buzzer mati
            updateFirebase("IDLE"); // Kirim status "IDLE" ke Firebase
        }
    }

    // Cek perintah dari serial untuk mengaktifkan atau menonaktifkan sistem
    if (Serial.available()) {
        char cmd = Serial.read();
        if (cmd == '1') {
            setSystemState(true);  // Aktifkan sistem
        } else if (cmd == '0') {
            setSystemState(false); // Matikan sistem
        }
    }

    delay(100);  // Delay singkat untuk menghindari pembacaan sensor yang terlalu cepat
}