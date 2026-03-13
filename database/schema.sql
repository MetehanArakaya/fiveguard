-- FIVEGUARD DATABASE SCHEMA
-- AI Destekli FiveM Anti-Cheat Sistemi
-- Veritabanı: fiveguard_db

CREATE DATABASE IF NOT EXISTS fiveguard_db;
USE fiveguard_db;

-- =============================================
-- KULLANICI VE LİSANS YÖNETİMİ
-- =============================================

-- Lisans tablosu
CREATE TABLE licenses (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_key VARCHAR(255) UNIQUE NOT NULL,
    server_name VARCHAR(255) NOT NULL,
    server_ip VARCHAR(45) NOT NULL,
    max_players INT DEFAULT 128,
    status ENUM('active', 'suspended', 'expired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    last_heartbeat TIMESTAMP NULL,
    INDEX idx_license_key (license_key),
    INDEX idx_status (status)
);

-- Admin kullanıcıları
CREATE TABLE admin_users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('super_admin', 'admin', 'moderator', 'viewer') DEFAULT 'viewer',
    license_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE SET NULL,
    INDEX idx_username (username),
    INDEX idx_email (email)
);

-- =============================================
-- OYUNCU YÖNETİMİ
-- =============================================

-- Oyuncu bilgileri
CREATE TABLE players (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_id INT NOT NULL,
    identifier VARCHAR(255) NOT NULL, -- steam:, license:, discord: vb.
    name VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    hwid VARCHAR(255),
    first_join TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    playtime INT DEFAULT 0, -- dakika cinsinden
    total_connections INT DEFAULT 1,
    is_banned BOOLEAN DEFAULT FALSE,
    is_whitelisted BOOLEAN DEFAULT FALSE,
    trust_score DECIMAL(3,2) DEFAULT 5.00, -- 0.00-10.00 arası AI güven skoru
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    UNIQUE KEY unique_player (license_id, identifier),
    INDEX idx_identifier (identifier),
    INDEX idx_name (name),
    INDEX idx_ip (ip_address),
    INDEX idx_trust_score (trust_score)
);

-- =============================================
-- ANTI-CHEAT DETECTION LOGS
-- =============================================

-- Ana detection tablosu
CREATE TABLE detections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_id INT NOT NULL,
    player_id INT NOT NULL,
    detection_type ENUM(
        'godmode', 'speedhack', 'teleport', 'aimbot', 'esp', 'noclip', 
        'freecam', 'lua_executor', 'resource_injection', 'menu_injection',
        'damage_modifier', 'weapon_spawn', 'money_exploit', 'item_spawn',
        'vehicle_spawn', 'explosion_spam', 'particle_spam', 'chat_spam',
        'sql_injection', 'xss_attempt', 'suspicious_behavior'
    ) NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
    confidence_score DECIMAL(5,2) NOT NULL, -- AI güven skoru 0.00-100.00
    description TEXT,
    evidence JSON, -- Screenshot, koordinat, değer vb. kanıtlar
    ai_analysis JSON, -- AI modülünün analiz sonuçları
    action_taken ENUM('none', 'warn', 'kick', 'temp_ban', 'permanent_ban') DEFAULT 'none',
    is_false_positive BOOLEAN DEFAULT FALSE,
    admin_reviewed BOOLEAN DEFAULT FALSE,
    admin_notes TEXT,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    INDEX idx_detection_type (detection_type),
    INDEX idx_severity (severity),
    INDEX idx_confidence (confidence_score),
    INDEX idx_detected_at (detected_at),
    INDEX idx_player_detections (player_id, detected_at)
);

-- =============================================
-- BAN YÖNETİMİ
-- =============================================

-- Ban kayıtları
CREATE TABLE bans (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_id INT NOT NULL,
    player_id INT NOT NULL,
    admin_id INT,
    detection_id INT,
    ban_type ENUM('temporary', 'permanent', 'hardware') NOT NULL,
    reason TEXT NOT NULL,
    evidence JSON,
    banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    appeal_status ENUM('none', 'pending', 'approved', 'denied') DEFAULT 'none',
    appeal_reason TEXT,
    appeal_date TIMESTAMP NULL,
    unbanned_by INT,
    unbanned_at TIMESTAMP NULL,
    unban_reason TEXT,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES admin_users(id) ON DELETE SET NULL,
    FOREIGN KEY (detection_id) REFERENCES detections(id) ON DELETE SET NULL,
    FOREIGN KEY (unbanned_by) REFERENCES admin_users(id) ON DELETE SET NULL,
    INDEX idx_player_bans (player_id),
    INDEX idx_ban_type (ban_type),
    INDEX idx_active_bans (is_active, expires_at)
);

-- =============================================
-- YAPAY ZEKA VE DAVRANIŞSAL ANALİZ
-- =============================================

-- AI davranış profilleri
CREATE TABLE ai_behavior_profiles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    reaction_time_avg DECIMAL(6,3), -- milisaniye
    aim_accuracy DECIMAL(5,2), -- yüzde
    movement_patterns JSON, -- Hareket kalıpları
    play_style_analysis JSON, -- Oyun tarzı analizi
    anomaly_score DECIMAL(5,2) DEFAULT 0.00, -- Anomali skoru
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    INDEX idx_anomaly_score (anomaly_score),
    INDEX idx_last_updated (last_updated)
);

-- AI screenshot analizi
CREATE TABLE ai_screenshot_analysis (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    screenshot_path VARCHAR(500),
    analysis_result JSON, -- AI analiz sonuçları
    detected_menus JSON, -- Tespit edilen menüler
    confidence_score DECIMAL(5,2),
    is_suspicious BOOLEAN DEFAULT FALSE,
    analyzed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    INDEX idx_suspicious (is_suspicious),
    INDEX idx_confidence (confidence_score),
    INDEX idx_analyzed_at (analyzed_at)
);

-- =============================================
-- SUNUCU İSTATİSTİKLERİ VE PERFORMANS
-- =============================================

-- Sunucu performans metrikleri
CREATE TABLE server_metrics (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_id INT NOT NULL,
    cpu_usage DECIMAL(5,2),
    memory_usage DECIMAL(5,2),
    player_count INT,
    detection_count_hourly INT DEFAULT 0,
    false_positive_rate DECIMAL(5,2) DEFAULT 0.00,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    INDEX idx_recorded_at (recorded_at),
    INDEX idx_license_metrics (license_id, recorded_at)
);

-- =============================================
-- EVENT VE LOG SİSTEMİ
-- =============================================

-- Sistem logları
CREATE TABLE system_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_id INT NOT NULL,
    log_level ENUM('debug', 'info', 'warning', 'error', 'critical') NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'anticheat', 'api', 'auth', 'system'
    message TEXT NOT NULL,
    context JSON, -- Ek bağlam bilgileri
    user_id INT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES admin_users(id) ON DELETE SET NULL,
    INDEX idx_log_level (log_level),
    INDEX idx_category (category),
    INDEX idx_created_at (created_at),
    INDEX idx_license_logs (license_id, created_at)
);

-- Discord webhook konfigürasyonu
CREATE TABLE webhook_configs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_id INT NOT NULL,
    webhook_type ENUM('discord', 'slack', 'teams') DEFAULT 'discord',
    webhook_url VARCHAR(500) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    events JSON, -- Hangi eventlerde tetiklenecek
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    INDEX idx_license_webhooks (license_id)
);

-- =============================================
-- KONFİGÜRASYON VE AYARLAR
-- =============================================

-- Sunucu konfigürasyonları
CREATE TABLE server_configs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_id INT NOT NULL,
    config_key VARCHAR(100) NOT NULL,
    config_value JSON NOT NULL,
    config_type ENUM('anticheat', 'ui', 'api', 'ai', 'webhook') NOT NULL,
    is_encrypted BOOLEAN DEFAULT FALSE,
    updated_by INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    FOREIGN KEY (updated_by) REFERENCES admin_users(id) ON DELETE SET NULL,
    UNIQUE KEY unique_config (license_id, config_key),
    INDEX idx_config_type (config_type)
);

-- Whitelist/Blacklist yönetimi
CREATE TABLE access_lists (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_id INT NOT NULL,
    list_type ENUM('whitelist', 'blacklist') NOT NULL,
    entry_type ENUM('identifier', 'ip', 'hwid', 'name') NOT NULL,
    entry_value VARCHAR(255) NOT NULL,
    reason TEXT,
    added_by INT,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    FOREIGN KEY (added_by) REFERENCES admin_users(id) ON DELETE SET NULL,
    INDEX idx_list_type (list_type),
    INDEX idx_entry_type (entry_type),
    INDEX idx_entry_value (entry_value),
    INDEX idx_active_entries (is_active, expires_at)
);

-- =============================================
-- RAPORLAMA VE ANALİTİK
-- =============================================

-- Otomatik raporlar
CREATE TABLE automated_reports (
    id INT PRIMARY KEY AUTO_INCREMENT,
    license_id INT NOT NULL,
    report_type ENUM('daily', 'weekly', 'monthly') NOT NULL,
    report_data JSON NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (license_id) REFERENCES licenses(id) ON DELETE CASCADE,
    INDEX idx_report_type (report_type),
    INDEX idx_generated_at (generated_at)
);

-- =============================================
-- İNDEXLER VE OPTİMİZASYON
-- =============================================

-- Performans için ek indexler
CREATE INDEX idx_detections_recent ON detections(license_id, detected_at DESC);
CREATE INDEX idx_players_active ON players(license_id, last_seen DESC);
CREATE INDEX idx_bans_active ON bans(license_id, is_active, expires_at);

-- =============================================
-- FIVEGUARD MODÜL TABLOLARI
-- =============================================

-- Admin Abuse Detection Tabloları
CREATE TABLE fiveguard_admin_actions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    action_id VARCHAR(100) NOT NULL,
    admin_id INT NOT NULL,
    admin_name VARCHAR(255) NOT NULL,
    action_type VARCHAR(50) NOT NULL,
    target_player_id INT,
    target_player_name VARCHAR(255),
    parameters JSON,
    timestamp INT NOT NULL,
    reason TEXT,
    source VARCHAR(100),
    metadata JSON,
    INDEX idx_admin_id (admin_id),
    INDEX idx_action_type (action_type),
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE fiveguard_admin_suspicious_activities (
    id INT PRIMARY KEY AUTO_INCREMENT,
    activity_id VARCHAR(100) NOT NULL,
    admin_id INT NOT NULL,
    admin_name VARCHAR(255) NOT NULL,
    violation_type VARCHAR(50) NOT NULL,
    violation_data JSON,
    trigger_action JSON,
    timestamp INT NOT NULL,
    risk_level INT NOT NULL,
    handled BOOLEAN DEFAULT FALSE,
    INDEX idx_admin_id (admin_id),
    INDEX idx_violation_type (violation_type),
    INDEX idx_risk_level (risk_level),
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE fiveguard_admin_whitelist (
    id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT NOT NULL,
    admin_name VARCHAR(255) NOT NULL,
    reason TEXT,
    added_by VARCHAR(255),
    timestamp INT NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    INDEX idx_admin_id (admin_id),
    INDEX idx_active (active)
);

CREATE TABLE fiveguard_admin_suspensions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT NOT NULL,
    admin_name VARCHAR(255) NOT NULL,
    reason TEXT NOT NULL,
    duration INT NOT NULL,
    timestamp INT NOT NULL,
    expires_at INT NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    INDEX idx_admin_id (admin_id),
    INDEX idx_expires_at (expires_at),
    INDEX idx_active (active)
);

CREATE TABLE fiveguard_admin_warnings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT NOT NULL,
    admin_name VARCHAR(255) NOT NULL,
    reason TEXT NOT NULL,
    timestamp INT NOT NULL,
    INDEX idx_admin_id (admin_id),
    INDEX idx_timestamp (timestamp)
);

-- Cheat Detection Engine Tabloları
CREATE TABLE fiveguard_cheat_detections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    player_name VARCHAR(255) NOT NULL,
    detection_type VARCHAR(50) NOT NULL,
    detection_data JSON,
    severity VARCHAR(20) NOT NULL,
    timestamp INT NOT NULL,
    INDEX idx_player_id (player_id),
    INDEX idx_detection_type (detection_type),
    INDEX idx_severity (severity),
    INDEX idx_timestamp (timestamp)
);

-- ESX Security Module Tabloları
CREATE TABLE fiveguard_esx_detections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    player_name VARCHAR(255) NOT NULL,
    detection_type VARCHAR(50) NOT NULL,
    detection_data JSON,
    severity VARCHAR(20) NOT NULL,
    timestamp INT NOT NULL,
    INDEX idx_player_id (player_id),
    INDEX idx_detection_type (detection_type),
    INDEX idx_severity (severity),
    INDEX idx_timestamp (timestamp)
);

-- Network Security Layer Tabloları
CREATE TABLE fiveguard_network_detections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    player_name VARCHAR(255) NOT NULL,
    player_ip VARCHAR(45) NOT NULL,
    detection_type VARCHAR(50) NOT NULL,
    detection_data JSON,
    severity VARCHAR(20) NOT NULL,
    timestamp INT NOT NULL,
    INDEX idx_player_id (player_id),
    INDEX idx_player_ip (player_ip),
    INDEX idx_detection_type (detection_type),
    INDEX idx_severity (severity),
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE fiveguard_network_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_data JSON,
    timestamp INT NOT NULL,
    INDEX idx_player_id (player_id),
    INDEX idx_event_type (event_type),
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE fiveguard_banned_ips (
    id INT PRIMARY KEY AUTO_INCREMENT,
    ip_address VARCHAR(45) NOT NULL,
    reason TEXT NOT NULL,
    timestamp INT NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    UNIQUE KEY unique_ip (ip_address),
    INDEX idx_ip_address (ip_address),
    INDEX idx_active (active)
);

-- Entity Validation System Tabloları
CREATE TABLE fiveguard_entity_detections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    player_name VARCHAR(255) NOT NULL,
    detection_type VARCHAR(50) NOT NULL,
    detection_data JSON,
    severity VARCHAR(20) NOT NULL,
    timestamp INT NOT NULL,
    INDEX idx_player_id (player_id),
    INDEX idx_detection_type (detection_type),
    INDEX idx_severity (severity),
    INDEX idx_timestamp (timestamp)
);

-- Weapon Security Module Tabloları
CREATE TABLE fiveguard_weapon_detections (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    player_name VARCHAR(255) NOT NULL,
    detection_type VARCHAR(50) NOT NULL,
    detection_data JSON,
    severity VARCHAR(20) NOT NULL,
    timestamp INT NOT NULL,
    INDEX idx_player_id (player_id),
    INDEX idx_detection_type (detection_type),
    INDEX idx_severity (severity),
    INDEX idx_timestamp (timestamp)
);

-- OCR Handler Module Tabloları
CREATE TABLE fiveguard_ocr_results (
    id INT PRIMARY KEY AUTO_INCREMENT,
    request_id VARCHAR(100) NOT NULL,
    player_id INT NOT NULL,
    player_name VARCHAR(255) NOT NULL,
    detected BOOLEAN DEFAULT FALSE,
    confidence DECIMAL(5,2) DEFAULT 0.00,
    detection_type VARCHAR(50),
    trigger_type VARCHAR(50),
    reason TEXT,
    timestamp INT NOT NULL,
    ocr_data JSON,
    ai_data JSON,
    INDEX idx_request_id (request_id),
    INDEX idx_player_id (player_id),
    INDEX idx_detected (detected),
    INDEX idx_confidence (confidence),
    INDEX idx_timestamp (timestamp)
);

-- Genel Ban Tablosu (Fiveguard Specific)
CREATE TABLE fiveguard_bans (
    id INT PRIMARY KEY AUTO_INCREMENT,
    player_id INT NOT NULL,
    player_name VARCHAR(255) NOT NULL,
    reason TEXT NOT NULL,
    ban_type VARCHAR(50) NOT NULL,
    timestamp INT NOT NULL,
    expires_at INT,
    active BOOLEAN DEFAULT TRUE,
    INDEX idx_player_id (player_id),
    INDEX idx_ban_type (ban_type),
    INDEX idx_active (active),
    INDEX idx_expires_at (expires_at)
);

-- =============================================
-- BAŞLANGIÇ VERİLERİ
-- =============================================

-- Varsayılan admin kullanıcısı (şifre: admin123 - değiştirilmeli!)
INSERT INTO admin_users (username, email, password_hash, role) VALUES 
('admin', 'admin@fiveguard.com', '$2b$10$rQZ8kJQy5F5F5F5F5F5F5O', 'super_admin');

-- Varsayılan konfigürasyonlar
INSERT INTO server_configs (license_id, config_key, config_value, config_type) VALUES 
(1, 'max_warnings', '{"value": 3}', 'anticheat'),
(1, 'auto_ban_enabled', '{"value": true}', 'anticheat'),
(1, 'ai_confidence_threshold', '{"value": 85.0}', 'ai'),
(1, 'screenshot_interval', '{"value": 300}', 'ai'),
(1, 'theme', '{"primary": "#0066ff", "background": "#1a1a1a"}', 'ui');
