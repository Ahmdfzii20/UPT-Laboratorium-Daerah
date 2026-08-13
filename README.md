# UPT-Laboratorium-Daerah (Lapor Lab)

Sistem Informasi Laboratorium Kesehatan Daerah (Labkesda) yang dirancang untuk mempermudah monitoring, rekapitulasi, dan pelaporan data lab. Aplikasi ini mencakup dashboard untuk rekap data (bulanan/semester) dan fitur ekspor ke Excel secara otomatis.

## 🏗 Arsitektur Aplikasi

Aplikasi mobile ini dibangun menggunakan framework **Flutter** dan diintegrasikan dengan ekosistem **Firebase** sebagai backend (BaaS). Arsitektur kode berpusat pada pemisahan antara UI, logika bisnis (services), dan pengelolaan state.
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Backend/Database**: Firebase (Auth, Cloud Firestore, Firebase Storage)
- **Data Export & Processing**: Menggunakan service class (seperti `ExcelExportService`) yang di-inject untuk men-generate file `.xlsx` dengan package `excel`.

## 🚀 Tech Stack & Versi

- **Flutter / Dart SDK**: `^3.12.2` (Environment)
- **State Management**: `flutter_riverpod ^3.4.2`
- **Routing**: `go_router ^17.4.0`
- **Database / Backend**:
  - `firebase_core: ^4.13.0`
  - `firebase_auth: ^6.5.7`
  - `cloud_firestore: ^6.8.0`
  - `firebase_storage: ^13.4.6`
- **Tools Tambahan**:
  - `excel: ^4.0.6` (Untuk pembuatan laporan rekap Excel)
  - `path_provider: ^2.1.6` (Untuk akses penyimpanan lokal perangkat)
  - `share_plus: ^13.3.0` (Untuk membagikan file hasil ekspor)

## 👥 Aktor (Role Pengguna)

Secara umum, sistem ini dirancang untuk mengakomodasi aktor berikut (yang diatur melalui autentikasi Firebase):
1. **Admin / Petugas Labkesda Utama**: Memiliki akses ke Dashboard Dashboard Utama untuk memantau selutuh data rekapitulasi, memfilter data berdasarkan rentang waktu, dan mengekspor laporan akhir (Rekap per bulan atau per semester) ke format Excel.
2. **Faskes / Puskesmas**: Pengguna dari instansi kesehatan daerah (Puskesmas) yang memasukkan dan mengirimkan data pemeriksaan/kunjungan laboratorium secara berkala.

## ⚙️ Cara Pull dan Menjalankan Proyek

Berikut adalah langkah-langkah siap pakai (copy-paste) untuk men-setup dan menjalankan project ini di komputer Anda:

### 1. Prasyarat
Pastikan komputer Anda sudah terinstal:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (sesuaikan dengan versi `3.12.x` atau yang lebih baru).
- IDE pendukung (VS Code atau Android Studio).
- Emulator atau Real Device yang sudah terhubung.

### 2. Clone Repositori
Jalankan perintah ini di terminal Anda:
```bash
git clone https://github.com/Ahmdfzii20/UPT-Laboratorium-Daerah.git
cd UPT-Laboratorium-Daerah/labkesda_app
```

### 3. Install Dependencies
Unduh semua package yang diperlukan oleh Flutter:
```bash
flutter pub get
```

### 4. Konfigurasi Firebase
Karena aplikasi ini terhubung dengan Firebase, pastikan Anda memiliki file konfigurasi autentikasi dari Firebase Console:
- **Android**: Tempatkan `google-services.json` ke dalam folder `android/app/`.
- **iOS**: Tempatkan `GoogleService-Info.plist` ke dalam folder `ios/Runner/`.
*(Jika file ini di-ignore oleh git, silakan minta file konfigurasi tersebut kepada owner project).*

### 5. Menjalankan Aplikasi
Pilih device Anda (emulator atau perangkat fisik), lalu jalankan:
```bash
flutter run
```
*(Untuk mode release/build APK, gunakan `flutter build apk`)*
