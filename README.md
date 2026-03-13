# FIVEGUARD - AI Destekli FiveM Anti-Cheat Sistemi

![Fiveguard Logo](https://img.shields.io/badge/FIVEGUARD-AI%20Anti--Cheat-blue?style=for-the-badge&logo=shield)

## 🛡️ Genel Bakış

Fiveguard, FiveM sunucuları için gelişmiş yapay zekâ destekli anti-cheat sistemi ve bulut tabanlı web yönetim panelidir. Sunucu tarafı, istemci tarafı ve bulut tabanlı yönetim modüllerinden oluşan kapsamlı bir güvenlik ekosistemidir.

## 🚀 Özellikler

### 🧠 Yapay Zeka Modülleri
- **Anti On-Screen Menü**: AI görüntü işleme ile Lua menü tespiti
- **AI Sahne Algılama**: Araç ve oyuncu anomali analizi
- **AI Davranış Analizi**: İnsan dışı reflex tespiti
- **Makine Öğrenmesi**: Kendini öğrenen hile tespit sistemi

### 🔐 Güvenlik Katmanları
- **Sunucu Tarafı Koruma**: GodMode, SpeedHack, Teleport koruması
- **İstemci Tarafı Koruma**: Noclip, Aimbot, ESP koruması
- **Event Protection**: SQL Injection, para istismarı koruması
- **Network Security**: VPN/Proxy engelleme, DDoS koruması

### 🌐 Web Yönetim Paneli
- **Gerçek Zamanlı Dashboard**: Canlı oyuncu izleme
- **Lisans Yönetimi**: Bulut tabanlı lisans kontrolü
- **Log Sistemi**: Discord, dosya ve veritabanı logları
- **Multi-Language**: 20+ dil desteği

### 📊 Raporlama ve Analiz
- **Otomatik Raporlama**: Haftalık/aylık güvenlik raporları
- **Delil Toplama**: Screenshot, video kayıt sistemi
- **AI Replay**: Hile anını yapay zekâyla yeniden oynatma

## 📁 Proje Yapısı

```
fiveguard/
├── server/           # FiveM sunucu tarafı scriptleri
├── client/           # FiveM istemci tarafı scriptleri
├── web-panel/        # React web yönetim paneli
├── api/              # Node.js backend API
├── database/         # MySQL veritabanı şemaları
├── ai-modules/       # Python AI modülleri
├── config/           # Konfigürasyon dosyaları
└── docs/             # Dokümantasyon
```

## 🛠️ Kurulum

### Gereksinimler
- FiveM Server
- MySQL 8.0+
- Node.js 18+
- Python 3.9+
- Redis (opsiyonel)

### Hızlı Başlangıç
1. Repository'yi klonlayın
2. Veritabanını kurun: `mysql < database/schema.sql`
3. FiveM resource'unu yükleyin
4. Web panelini başlatın: `cd web-panel && npm start`
5. API'yi çalıştırın: `cd api && npm start`

## 🎨 Tasarım Teması
- **Renk Paleti**: Koyu arka plan, mavi neon detaylar
- **UI Framework**: React + Tailwind CSS
- **Animasyonlar**: Framer Motion
- **Font**: Inter, Poppins, Orbitron


---
**Fiveguard** - Yapay zekâ destekli, bulut tabanlı FiveM anti-cheat sistemi.
