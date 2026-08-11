# Step-by-Step Setup Firebase (Versi Gratis / Spark) — Sistem Pelaporan Lab Puskesmas-Labkesda

Panduan ini melanjutkan **Fase 0-3** dari PRD. **Versi ini 100% gratis** — tidak perlu upgrade Blaze, tidak perlu kartu kredit, tidak pakai Cloud Functions. Ikuti berurutan.

---

## Langkah 1 — Buat Project Firebase

1. Buka [console.firebase.google.com](https://console.firebase.google.com), login dengan akun Google yang akan jadi pemilik project.
2. Klik **"Add project"** (Tambah project).
3. Nama project: misal `labkesda-deliserdang`.
4. Google Analytics: **matikan saja** (tidak dibutuhkan untuk app internal seperti ini).
5. Tunggu Firebase selesai provisioning project (~30 detik), lalu klik **Continue**.

**Hasil:** project Firebase kosong, masih di paket **Spark (gratis)** — tidak perlu diubah, tidak perlu masukkan kartu kredit sama sekali.

---

## Langkah 2 — Aktifkan Authentication

1. Sidebar kiri → **Build → Authentication** → **"Get started"**.
2. Tab **Sign-in method** → klik **Email/Password** → toggle **Enable** → **Save**.

---

## Langkah 3 — Aktifkan Cloud Firestore

1. Sidebar kiri → **Build → Firestore Database** → **"Create database"**.
2. Pilih **Start in production mode** (bukan test mode) — kita akan tulis security rules sendiri.
3. Pilih region **`asia-southeast2`** (Jakarta) — terdekat dari Sumatera Utara, latensi terbaik. **Tidak bisa diubah setelah dipilih**, pastikan benar.
4. Klik **Enable**.

**Catatan biaya:** Firestore di paket Spark punya kuota gratis harian (50rb read, 20rb write, 20rb delete per hari) — untuk 35 puskesmas dengan aktivitas bulanan, ini jauh lebih dari cukup, hampir mustahil terlampaui.

---

## Langkah 4 — Aktifkan Storage (Opsional)

Sidebar kiri → **Build → Storage** → **"Get started"** → production mode → region sama (`asia-southeast2`). Bisa di-skip jika tidak butuh simpan file Excel di cloud.

---

## Langkah 5 — Aktifkan Hosting (untuk Web Admin Labkesda)

1. Sidebar kiri → **Build → Hosting** → **"Get started"**.
2. Ikuti wizard-nya, tapi **belum perlu deploy apapun sekarang** — cukup sampai step "site terdaftar". Deploy sesungguhnya dilakukan di Langkah 18 setelah aplikasi Flutter siap.

**Catatan biaya:** Hosting Spark punya kuota gratis 10GB storage + 360MB/hari transfer — untuk 1 aplikasi internal kecil, ini sangat lebih dari cukup.

---

## Langkah 6 — Install Node.js (untuk Firebase CLI & script seed data)

Node.js tetap dibutuhkan **hanya untuk menjalankan Firebase CLI dan script seed data 1x jalan** — bukan untuk Cloud Functions (kita tidak pakai Cloud Functions sama sekali).

1. Download & install versi **LTS terbaru** dari [nodejs.org](https://nodejs.org).
2. Verifikasi:
   ```bash
   node --version
   npm --version
   ```

---

## Langkah 7 — Install Firebase CLI

```bash
npm install -g firebase-tools
firebase --version
firebase login
```

Login akan membuka browser untuk autentikasi dengan akun Google yang sama seperti Langkah 1.

---

## Langkah 8 — Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
flutterfire --version
```

Pastikan `$HOME/.pub-cache/bin` ada di PATH sistem Anda.

---

## Langkah 9 — Buat Project Flutter (jika belum dibuat)

```bash
flutter create labkesda_app
cd labkesda_app
flutter --version
```

---

## Langkah 10 — Hubungkan Flutter ke Firebase (`flutterfire configure`)

```bash
flutterfire configure
```

Ikuti prompt:
1. Pilih project `labkesda-deliserdang`.
2. **Centang ketiganya**: `android`, `ios`, `web`.
3. Confirm application id Android (misal `id.go.deliserdangkab.labkesda`) & bundle id iOS.
4. Tunggu selesai — akan otomatis generate `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, dan mendaftarkan Web App.

---

## Langkah 11 — Tambahkan Dependencies Firebase

```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutter pub get
```

**Catatan:** tidak ada `cloud_functions` di daftar ini — memang sengaja tidak dipakai di versi gratis ini.

---

## Langkah 12 — Inisialisasi Firebase di `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

Test:

```bash
flutter run -d chrome     # test target web (Admin Labkesda)
flutter run                # test target mobile yang terhubung (Petugas Puskesmas)
```

---

## Langkah 13 — Tulis Firestore Security Rules (Role via Firestore Doc, Bukan Custom Claims)

Karena tidak ada Cloud Functions, role (`puskesmas`/`admin`) disimpan sebagai **field biasa** di dokumen `/users/{uid}`, dan rules membacanya via `get()`.

Jalankan dulu jika belum ada file rules:

```bash
firebase init firestore
```
(pilih project yang sama, gunakan nama default `firestore.rules`)

Isi `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }

    function isAdmin() {
      return request.auth != null && getUserData().role == 'admin';
    }

    function isPuskesmasOwner(puskesmasId) {
      return request.auth != null
        && getUserData().role == 'puskesmas'
        && getUserData().puskesmasId == puskesmasId;
    }

    function deadlineSettings() {
      return get(/databases/$(database)/documents/settings/deadline).data;
    }

    // Batas revisi: request.time harus masih sebelum disubmitPada + batasRevisiHari
    function masihBisaDirevisi(laporan) {
      return laporan.disubmitPada == null
        || request.time < laporan.disubmitPada
             + duration.value(deadlineSettings().batasRevisiHari, 'd');
    }

    match /users/{uid} {
      allow read: if request.auth != null && (request.auth.uid == uid || isAdmin());
      allow create, update: if isAdmin() || request.auth.uid == uid;
      allow delete: if isAdmin();
    }

    match /puskesmas/{id} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    match /examTypes/{id} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    match /settings/{id} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    match /laporan/{laporanId} {
      allow read: if isAdmin() || isPuskesmasOwner(resource.data.puskesmasId);
      allow create: if isPuskesmasOwner(request.resource.data.puskesmasId);
      allow update: if isAdmin()
        || (isPuskesmasOwner(resource.data.puskesmasId) && masihBisaDirevisi(resource.data));
      allow delete: if isAdmin();

      match /histori/{historiId} {
        allow read: if isAdmin()
          || isPuskesmasOwner(get(/databases/$(database)/documents/laporan/$(laporanId)).data.puskesmasId);
        allow create: if request.auth != null;
        allow update, delete: if false; // audit trail immutable
      }
    }
  }
}
```

Deploy:

```bash
firebase deploy --only firestore:rules
```

**Catatan penting:** karena banyak fungsi di atas memanggil `get()` (baca dokumen lain di dalam rules), setiap operasi akan menghabiskan sedikit lebih banyak kuota read gratis harian dibanding versi custom claims. Untuk skala 35 puskesmas ini **tidak masalah** — kuota gratis Firestore jauh lebih besar dari kebutuhan aktual aplikasi ini.

---

## Langkah 14 — Buat Akun Admin Labkesda Pertama (Manual)

1. Firebase Console → Authentication → **Add user** → masukkan email & password admin pertama → **Add user**. Catat **UID** yang muncul.
2. Buat file `seed-data.js` di folder lokal terpisah (bukan bagian dari app Flutter):
   ```javascript
   const admin = require("firebase-admin");
   const serviceAccount = require("./serviceAccountKey.json");

   admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
   const db = admin.firestore();

   const ADMIN_UID = "PASTE_UID_DI_SINI";

   const puskesmasList = [
     "GALANG", "PAGAR MERBAU", "DALU SEPULUH", /* ... lengkapi 35 nama dari Excel ... */
   ];

   const examTypes = [
     "DARAH RUTIN", "HB STIK", "LEUCOSIT", /* ... lengkapi 38 dari Lampiran A PRD ... */
   ];

   async function seed() {
     const batch = db.batch();

     // Akun admin pertama
     batch.set(db.collection("users").doc(ADMIN_UID), {
       email: "admin@labkesda.go.id", // ganti sesuai email asli
       role: "admin",
       nama: "Admin Labkesda",
       aktif: true,
     });

     puskesmasList.forEach((nama, i) => {
       const ref = db.collection("puskesmas").doc();
       batch.set(ref, { nama, aktif: true, urutan: i + 1 });
     });

     examTypes.forEach((nama, i) => {
       const ref = db.collection("examTypes").doc();
       batch.set(ref, { nama, aktif: true, urutan: i + 1 });
     });

     batch.set(db.collection("settings").doc("deadline"), {
       batasInputHari: 10,
       satuanBatasInput: "kalender",
       batasRevisiHari: 10,
     });

     await batch.commit();
     console.log("Seed selesai — admin, 35 puskesmas, 38 jenis pemeriksaan, settings.");
   }

   seed();
   ```
3. Download `serviceAccountKey.json`: Firebase Console → ⚙️ **Project Settings** → **Service accounts** → **Generate new private key**. Simpan di folder yang sama — **jangan pernah commit ke git**, tambahkan ke `.gitignore`.
4. Install dependency & jalankan:
   ```bash
   npm install firebase-admin
   node seed-data.js
   ```
5. Verifikasi: login dengan akun admin ini di app nanti — pastikan aplikasi membaca `/users/{uid}` dan mendapat `role: "admin"`.

**Catatan:** `firebase-admin` (dipakai di script ini) berjalan **lokal di komputer Anda**, bukan Cloud Functions — jadi tetap gratis, hanya dipakai 1-2 kali saja untuk seed data awal.

---

## Langkah 15 — Cara Admin Membuat Akun Puskesmas Baru (Tanpa Cloud Function)

Di dalam aplikasi Flutter, gunakan **secondary Firebase App instance** supaya Admin Labkesda bisa membuat akun baru tanpa ter-logout dari sesinya sendiri:

```dart
Future<void> buatAkunPuskesmas({
  required String email,
  required String password,
  required String puskesmasId,
  required String nama,
}) async {
  // 1. Buat instance Firebase App kedua yang sementara
  final secondaryApp = await Firebase.initializeApp(
    name: 'secondary',
    options: Firebase.app().options,
  );

  try {
    // 2. Buat user baru di instance kedua (tidak memengaruhi sesi admin di instance utama)
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 3. Tulis dokumen /users/{uid} dari instance UTAMA (pakai sesi admin yang login)
    await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'role': 'puskesmas',
      'puskesmasId': puskesmasId,
      'nama': nama,
      'aktif': true,
    });

    // 4. Sign out dari instance kedua supaya bersih
    await secondaryAuth.signOut();
  } finally {
    // 5. Hapus instance kedua
    await secondaryApp.delete();
  }
}
```

Ini murni logika client-side, tidak butuh server tambahan sama sekali.

---

## Langkah 16 — Hitung Status "Overdue" & "Terkunci" di Client (Tanpa Scheduled Function)

Contoh helper Dart untuk dipakai di Dashboard Puskesmas & Admin:

```dart
bool isOverdue({
  required int tahun,
  required int bulan,
  required String? status,
  required int batasInputHari,
}) {
  if (status == 'submitted') return false;
  final batasWaktu = DateTime(tahun, bulan + 1, 1).add(Duration(days: batasInputHari));
  return DateTime.now().isAfter(batasWaktu);
}

bool masihBisaDirevisi({
  required DateTime? disubmitPada,
  required int batasRevisiHari,
}) {
  if (disubmitPada == null) return true; // belum pernah submit, masih draft, bebas edit
  final batasRevisi = disubmitPada.add(Duration(days: batasRevisiHari));
  return DateTime.now().isBefore(batasRevisi);
}
```

Nilai `batasInputHari` & `batasRevisiHari` diambil dari `/settings/deadline` (di-load sekali saat app start atau via `StreamProvider` Riverpod supaya reaktif kalau admin mengubahnya).

---

## Langkah 17 — Test dengan Firebase Emulator Suite (Opsional tapi Disarankan)

Emulator tetap gratis dan tidak butuh Cloud Functions untuk Auth & Firestore:

```bash
firebase init emulators
```
Pilih: **Authentication Emulator**, **Firestore Emulator**.

```bash
firebase emulators:start
```

Di `main.dart` (dibungkus `kDebugMode`):

```dart
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

---

## Langkah 18 — Deploy Web ke Firebase Hosting

Setelah aplikasi Flutter Web (Dashboard Admin Labkesda) siap:

```bash
flutter build web
firebase deploy --only hosting
```

Firebase akan memberi URL publik (misal `https://labkesda-deliserdang.web.app`) yang bisa langsung dibagikan ke Admin Labkesda.

---

## Ringkasan Urutan Command (Quick Reference)

```bash
# 1. Tools
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login

# 2. Project Flutter
flutter create labkesda_app
cd labkesda_app
flutterfire configure

# 3. Dependencies (TANPA cloud_functions)
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutter pub get

# 4. Firestore rules
firebase init firestore
firebase deploy --only firestore:rules

# 5. (Opsional) Emulator untuk development
firebase init emulators
firebase emulators:start

# 6. Seed data (sekali jalan, script Node.js lokal)
npm install firebase-admin
node seed-data.js

# 7. Deploy web
flutter build web
firebase deploy --only hosting
```

---

## Checklist Sebelum Lanjut ke Fase 4 (Coding Dashboard Puskesmas)

- [ ] Project Firebase aktif, **tetap paket Spark/gratis** — tidak ada billing account terhubung
- [ ] Authentication (Email/Password) aktif
- [ ] Firestore aktif, region `asia-southeast2`, production mode
- [ ] `flutterfire configure` sukses, `firebase_options.dart` ter-generate untuk android/ios/web
- [ ] `main.dart` berhasil inisialisasi Firebase tanpa error
- [ ] Security rules ter-deploy (versi role-via-Firestore-doc, bukan custom claims)
- [ ] Akun Admin Labkesda pertama berhasil dibuat, dokumen `/users/{uid}` punya `role: "admin"`
- [ ] 35 puskesmas & 38 jenis pemeriksaan ter-seed di Firestore
- [ ] `/settings/deadline` ter-seed dengan nilai default
- [ ] Fungsi `buatAkunPuskesmas` (secondary app instance) sudah ditest berhasil membuat akun baru tanpa mengganggu sesi admin

Setelah semua item ini centang, Anda siap mulai Fase 4 (form input puskesmas) & Fase 5 (dashboard admin) sesuai roadmap PRD — **dan tidak ada biaya Firebase sama sekali** selama skala aplikasi tetap di kisaran 35 puskesmas.
