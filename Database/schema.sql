CREATE DATABASE home_security;

USE home_security;

CREATE TABLE logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    state VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    image LONGBLOB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
