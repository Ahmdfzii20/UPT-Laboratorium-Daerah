# PRD — Sistem Pelaporan Hasil Pemeriksaan Laboratorium
## Puskesmas → Labkesda Kabupaten Deli Serdang

**Versi:** 1.0 (Draft)
**Tanggal:** 8 Agustus 2026
**Platform:** Flutter 3.44.3 (pure Flutter, tanpa backend custom) + Firebase — **Mobile (Android/iOS) untuk Petugas Puskesmas, Flutter Web untuk Admin Labkesda**
**Paket Firebase:** **Spark (gratis, tanpa Cloud Functions)** — dikonfirmasi, lihat §6.3 dan §10
**Disusun berdasarkan:** analisis file `REKAP_PUSKESMAS_THN_2026.xlsx` (data riil existing)

---

## 1. Latar Belakang

Labkesda Kabupaten Deli Serdang menerima laporan bulanan hasil pemeriksaan laboratorium dari **35 Puskesmas/UPT** (termasuk UPT.LABKESMAS TK 2). Saat ini proses berjalan manual:

1. Setiap puskesmas mengisi jumlah pemeriksaan per jenis pemeriksaan secara manual di Excel, lalu mengirim file ke Labkesda (kemungkinan via WA/email).
2. Admin Labkesda merekap ulang secara manual ke dalam satu file Excel gabungan (1 sheet per bulan + 1 sheet rekap semester).

**Masalah:** rawan human error saat rekap ulang, tidak ada histori/audit trail, tidak ada validasi input, proses lambat, dan format sering tidak konsisten antar puskesmas.

**Tujuan aplikasi:** menggantikan proses ini dengan sistem digital berbasis Flutter + Firebase, di mana puskesmas input langsung ke sistem, dan Labkesda otomatis menerima data yang sudah terekap — tanpa proses salin-ulang manual.

---

## 2. Analisis Struktur Data Existing (Sumber Kebenaran)

Dari file Excel yang diberikan, ditemukan struktur berikut — **ini menjadi dasar data model aplikasi**:

| Elemen | Detail |
|---|---|
| Unit pelapor | 35 Puskesmas/UPT (nama tetap/master data, contoh: Galang, Pagar Merbau, Dalu Sepuluh, ..., UPT.LABKESMAS TK 2 Deli Serdang) |
| Periode | 1 sheet per bulan (Januari s.d. Desember) |
| Jenis pemeriksaan | **38 jenis tetap** (lihat lampiran A) — bukan free text, bukan nama penyakit |
| Nilai yang diinput | **Angka (integer) = jumlah pemeriksaan** yang dilakukan puskesmas tsb untuk jenis pemeriksaan tsb, dalam bulan tsb |
| Baris total | Baris "JUMLAH" = SUM otomatis per kolom (per jenis pemeriksaan, seluruh puskesmas) |
| Rekap semester | Sheet terpisah = SUM 6 bulan per puskesmas per jenis pemeriksaan (Semester I: Jan–Jun) |

**Catatan penting (perlu konfirmasi Anda):**
- Ini adalah **data agregat/tally**, bukan pencatatan per pasien dengan nama/diagnosis. Jadi 1 laporan puskesmas per bulan = 1 form berisi 38 angka.
- "Pencarian nama penyakit" pada requirement awal saya terjemahkan menjadi **pencarian/filter jenis pemeriksaan** (dari 38 jenis) saat mengisi form — karena memang tidak ada field nama penyakit di data existing.
- Jika ternyata Labkesda ke depan **ingin** mulai mencatat data per-pasien (nama pasien, NIK, diagnosis, dsb) — itu perubahan besar pada data model dan sebaiknya jadi **Fase 2 terpisah**, bukan digabung di MVP ini. PRD ini saya susun untuk mereplikasi & mendigitalkan proses yang sudah berjalan (agregat bulanan).

---

## 3. Pengguna & Peran (Roles)

| Role | Deskripsi | Akses |
|---|---|---|
| **Petugas Puskesmas** | Staf lab di tiap puskesmas — **1 akun = 1 puskesmas** (dikonfirmasi, tidak multi-user per puskesmas di MVP) | Input, edit/revisi data puskesmas sendiri, lihat histori sendiri |
| **Admin Labkesda** | Staf Labkesda kabupaten — role tunggal, tidak ada tingkatan Super Admin terpisah | Lihat semua data seluruh puskesmas, rekap otomatis, export Excel, kelola master data (puskesmas & jenis pemeriksaan), kelola akun petugas puskesmas (tambah/nonaktifkan/reset password), atur **batas waktu input & revisi** (§6), audit log |

**Perubahan dari draft sebelumnya:** role **Super Admin dihapus/dilebur ke Admin Labkesda**. Jadi hanya ada 2 role di sistem: `puskesmas` dan `admin`. Semua kewenangan pengelolaan user, master data, dan pengaturan sistem melekat langsung pada Admin Labkesda — tidak perlu role terpisah. Ini menyederhanakan custom claims, security rules, dan UI (tidak perlu 2 varian dashboard admin).

**Asumsi skala:** 1 kabupaten, ±35 unit pelapor, ~35–50 akun petugas puskesmas, beberapa akun admin Labkesda. Ini termasuk skala kecil-menengah — cocok untuk Firestore tanpa masalah performa maupun biaya berarti.

---

## 4. Alur Utama (User Flow)

### 4.1 Alur Petugas Puskesmas
1. Login (email & password via Firebase Auth) → akun sudah terdaftar & terikat ke 1 puskesmas tertentu (bukan self-register bebas).
2. Masuk ke Dashboard Puskesmas → lihat status laporan bulan berjalan (Belum diisi / Draft / Terkirim / Direvisi Labkesda).
3. Pilih/pilih otomatis bulan & tahun pelaporan (default: bulan berjalan).
4. Isi form 38 jenis pemeriksaan → tersedia search box untuk cari jenis pemeriksaan dengan cepat (karena 38 field cukup panjang untuk di-scroll).
5. Simpan sebagai **Draft** (bisa disimpan bertahap, tidak harus sekali isi penuh) atau **Submit** (kirim final ke Labkesda).
6. Setelah submit, data berstatus locked/terkirim → jika ingin revisi, ada mekanisme **"Ajukan Revisi"** (lihat aturan bisnis §6).
7. Bisa melihat & mencari histori laporan bulan-bulan sebelumnya.

### 4.2 Alur Admin Labkesda
1. Login (email & password, akun admin terpisah) — via **aplikasi Flutter Web** (dikonfirmasi: Admin Labkesda memakai versi Web, bukan mobile, karena kerja rekap lebih nyaman di layar besar).
2. Dashboard menampilkan status semua puskesmas per bulan berjalan (siapa sudah submit, siapa belum, siapa terlambat).
3. Bisa membuka rekap tabel gabungan (format sama seperti Excel existing: baris = puskesmas, kolom = 38 jenis pemeriksaan, ada baris JUMLAH otomatis).
4. Bisa filter per bulan/per semester/per tahun, per puskesmas, atau per jenis pemeriksaan.
5. Bisa export ke Excel dengan format yang sama persis seperti file existing (agar tidak mengganggu proses pelaporan lanjutan mereka ke Dinkes Provinsi/lainnya).
6. Bisa membuka detail histori edit satu laporan (audit trail).
7. **Tidak ada approval manual wajib** (dikonfirmasi) — Admin Labkesda cukup memakai mekanisme **"Minta Revisi"** jika ada data yang janggal; laporan yang disubmit otomatis masuk rekap tanpa perlu di-approve satu-satu.

---

## 5. Fitur Detail

### 5.1 Dashboard Puskesmas
- Login/logout, ganti password, lupa password (reset via email).
- Form input jumlah pemeriksaan (38 field angka), per bulan.
- **Search/filter jenis pemeriksaan** dalam form (agar tidak perlu scroll manual di antara 38 field).
- Simpan draft (autosave opsional) & submit final.
- **Update/revisi data yang sudah diinput** — dengan aturan: revisi bebas selama status masih Draft; setelah Submit, revisi butuh alasan (catatan revisi) dan tercatat di histori (lihat §6).
- **Pencarian data** — cari laporan berdasarkan bulan/tahun, status, atau jenis pemeriksaan tertentu (mis. "tampilkan semua bulan di mana HIV > 0").
- Riwayat/histori laporan (list semua bulan yang pernah diinput + statusnya).
- Notifikasi/reminder pengingat jika laporan bulan berjalan belum diisi mendekati akhir bulan (opsional, via local notification atau badge di dashboard).
- Lihat profil puskesmas (nama, kode, kecamatan).

### 5.2 Dashboard Labkesda (Admin) — dibangun sebagai **Flutter Web**
- Login/logout, manajemen akun: tambah/nonaktifkan akun petugas puskesmas, reset password (semua kewenangan ini melekat pada 1 role Admin Labkesda, tidak ada role terpisah).
- **Monitoring status pelaporan** — matriks 35 puskesmas x 12 bulan, warna status (belum isi/draft/submit/terlambat/revisi diminta).
- **Pengaturan batas waktu (deadline settings)** — form sederhana untuk mengatur `batasInputHari` (X) dan `batasRevisiHari` (Y) beserta satuannya (hari kalender/hari kerja), tersimpan di `/settings/deadline` dan berlaku untuk seluruh puskesmas (lihat §6.1 & §6.2).
- **Rekap tabel gabungan otomatis** — persis format Excel existing (per bulan & per semester), dengan baris JUMLAH otomatis (tidak perlu SUM manual lagi).
- **Export Excel** — generate file .xlsx dengan struktur sama seperti file existing (per sheet bulan + sheet semester), sehingga bisa langsung dipakai untuk pelaporan lanjutan.
- **Filter & pencarian lanjutan** — per puskesmas, per jenis pemeriksaan, per rentang tanggal, per status.
- **Grafik/dashboard ringkas** (opsional tapi direkomendasikan) — tren jumlah pemeriksaan per jenis dari waktu ke waktu, top jenis pemeriksaan, puskesmas dengan laporan terlambat.
- **Audit trail** — histori siapa mengubah data apa dan kapan (penting untuk akuntabilitas data kesehatan).
- **Kelola master data jenis pemeriksaan** — CRUD penuh (tambah/edit/nonaktifkan) daftar 38 jenis pemeriksaan, karena dikonfirmasi daftar ini **harus fleksibel**, bisa berubah sewaktu-waktu tanpa update aplikasi. Ini fitur inti MVP, bukan fase 2.
- **Minta Revisi** laporan (mekanisme approval yang dipakai, tanpa approval manual wajib — lihat §6), termasuk **override/buka kunci** laporan yang sudah lewat batas revisi (§6.2).

---

## 6. Aturan Bisnis (Business Rules)

**Dikonfirmasi:** mekanisme approval memakai **"Minta Revisi"**, bukan approval manual per-laporan. Batas waktu input & revisi **dikonfigurasi oleh Admin Labkesda**, bukan hardcode di aplikasi.

- **Status laporan:** `draft` → `submitted` → (opsional) `revision_requested` → `submitted` (setelah diperbaiki).
- **Tidak ada approval manual wajib** — begitu puskesmas submit, data otomatis masuk rekap Labkesda (mengurangi friksi, sesuai tujuan awal: mempercepat proses). Admin Labkesda cukup "meminta revisi" jika data terlihat janggal (misalnya angka 0 semua atau anomali), yang akan mengembalikan status ke draft dengan catatan.
- **Satu laporan per puskesmas per bulan** (unique constraint) — tidak boleh dobel.
- **Nilai default 0** untuk jenis pemeriksaan yang tidak dilakukan bulan itu (bukan kosong/null), konsisten dengan data existing.

### 6.1 Batas Waktu Input (Deadline Input) — Dapat Diatur Admin Labkesda

- Admin Labkesda menetapkan **batas waktu input** laporan bulanan dari dashboard-nya sendiri, dalam bentuk **jumlah hari** dihitung dari awal bulan berikutnya (periode laporan bulan `N` harus diinput/disubmit paling lambat `X` hari setelah bulan `N` berakhir).
- Nilai `X` **bisa diubah sewaktu-waktu oleh Admin Labkesda** melalui pengaturan sistem — contoh: 5 hari, 10 hari, dsb. Tidak di-hardcode di kode aplikasi.
- **Dikonfirmasi: satuan default = hari kalender** (bukan hari kerja) — jadi "10 hari" berarti 10 hari kalender berturut-turut termasuk Sabtu/Minggu, dihitung langsung dari `disubmitPada`/awal bulan berikutnya tanpa perlu exclude weekend atau kalender hari libur. Ini menyederhanakan Cloud Function terjadwal (tidak perlu tabel hari libur nasional).
- Field `satuanBatasInput` di `/settings/deadline` tetap disediakan sebagai opsi ("kalender" vs "kerja") untuk fleksibilitas masa depan, tapi **MVP hanya mengimplementasikan hari kalender**; opsi hari kerja bisa jadi pengembangan lanjutan jika suatu saat dibutuhkan.
- Setelah batas waktu input terlewati **dan laporan masih berstatus `draft` (belum pernah disubmit)**, laporan dianggap **"Terlambat" (`overdue`)** — tetap bisa diisi & disubmit oleh puskesmas (tidak diblokir total, karena data kesehatan tetap harus masuk), status keterlambatan ini **dihitung langsung di aplikasi** (bandingkan tanggal sekarang vs deadline) tiap kali data ditampilkan, bukan field yang di-update oleh proses background (lihat §6.3).

### 6.2 Batas Waktu Revisi Setelah Submit — Dapat Diatur Admin Labkesda (sama seperti §6.1)

- Sama seperti batas waktu input, **batas waktu revisi setelah submit juga ditetapkan oleh Admin Labkesda** dalam bentuk jumlah hari (`Y` hari), dihitung sejak tanggal laporan pertama kali disubmit (`disubmitPada`) — bukan nilai tetap 7 hari seperti draft sebelumnya.
- Selama masih dalam periode `Y` hari tsb, puskesmas bebas mengedit laporan yang sudah disubmit; setiap perubahan tetap tercatat di sub-collection `histori` (audit trail).
- Setelah `Y` hari terlewati, laporan **terkunci** bagi petugas puskesmas — status kunci ini ditegakkan langsung oleh **Firestore Security Rules** (bandingkan `request.time` vs `disubmitPada + batasRevisiHari` saat rules dievaluasi), bukan oleh field `lockedPada` yang di-set proses server terjadwal (lihat §6.3). Untuk revisi setelah periode ini, hanya Admin Labkesda yang bisa membuka kunci/override data — dengan alasan wajib diisi, dan tercatat di audit log.
- `X` (batas input) dan `Y` (batas revisi) adalah **dua pengaturan terpisah** yang masing-masing bisa diubah independen oleh Admin Labkesda, meski defaultnya bisa disamakan nilainya (misalnya sama-sama 10 hari) jika Anda mau.

### 6.3 Versi Gratis (Spark) — Tanpa Cloud Functions

**Dikonfirmasi:** project ini dibangun di paket **Firebase Spark (gratis, tanpa kartu kredit)**. Ini mengubah cara §6.1 & §6.2 ditegakkan secara teknis:

| Aspek | Versi awal (butuh Blaze) | Versi gratis (Spark) — dipakai sekarang |
|---|---|---|
| Status `overdue` | Di-set oleh scheduled Cloud Function harian, disimpan sebagai field | **Dihitung on-the-fly** di Flutter (client) setiap laporan ditampilkan: `now > awalBulanBerikutnya + batasInputHari` |
| Status kunci revisi | Field `lockedPada` di-set oleh scheduled Cloud Function | **Dihitung langsung oleh Firestore Security Rules** saat ada percobaan `update`, membandingkan `request.time` dengan `resource.data.disubmitPada + batasRevisiHari` |
| Role & custom claims | Custom claims via Cloud Function `setUserRole` | **Role disimpan sebagai field biasa** di dokumen `/users/{uid}`, security rules baca lewat `get(/databases/$(database)/documents/users/$(request.auth.uid))` |
| Admin bikin akun puskesmas baru | Callable Cloud Function | **Secondary Firebase App instance** di sisi Flutter (admin membuat akun Auth baru tanpa ter-logout dari akunnya sendiri) — detail teknis di §10 |

**Konsekuensi yang perlu diketahui:**
- Field `overdue` dan `lockedPada` **tidak lagi disimpan** di dokumen `laporan` (dihapus dari data model §7) — status ini murni hasil kalkulasi, dibaca dari `/settings/deadline` + timestamp laporan, setiap kali dibutuhkan.
- Tidak ada proses yang "mengunci otomatis tengah malam" — laporan baru benar-benar tertolak diedit **saat ada percobaan edit** dan dievaluasi oleh rules saat itu juga. Untuk kebutuhan aplikasi ini (bukan sistem finansial real-time), ini cukup memadai.
- Kalau di masa depan Anda upgrade ke Blaze (misalnya untuk notifikasi push otomatis atau server-side Excel generation), arsitektur ini tetap kompatibel — tinggal tambah Cloud Functions tanpa perlu ubah struktur data yang sudah ada.

---

## 7. Data Model (Firestore)

Struktur koleksi diusulkan sebagai berikut:

```
/puskesmas/{puskesmasId}
  - nama: string
  - kode: string
  - kecamatan: string
  - aktif: bool

/examTypes/{examTypeId}
  - nama: string            // contoh: "DARAH RUTIN"
  - urutan: number          // untuk urutan tampilan form, sama seperti kolom Excel
  - aktif: bool
  - kategori: string        // opsional, untuk grouping (Darah/Urine/Serologi/dll)

/users/{uid}
  - email: string
  - role: "puskesmas" | "admin"        // hanya 2 role, tidak ada superadmin terpisah
  - puskesmasId: string     // hanya untuk role "puskesmas"
  - nama: string
  - aktif: bool

/laporan/{laporanId}          // laporanId = "{puskesmasId}_{tahun}_{bulan}"
  - puskesmasId: string
  - tahun: number
  - bulan: number (1-12)
  - status: "draft" | "submitted" | "revision_requested"
  - hasil: map<examTypeId, number>   // 38 key-value
  - dibuatOleh: uid
  - dibuatPada: timestamp
  - diubahPada: timestamp
  - disubmitPada: timestamp | null
  - catatanRevisi: string | null
  // Catatan: TIDAK ADA field `overdue`/`lockedPada` tersimpan — status ini dihitung
  // on-the-fly di client & divalidasi oleh security rules (§6.3), bukan disimpan permanen,
  // karena tidak ada Cloud Function terjadwal di paket Spark (gratis).

/laporan/{laporanId}/histori/{historiId}   // sub-collection audit trail
  - diubahOleh: uid
  - diubahPada: timestamp
  - perubahan: map              // snapshot before/after (opsional, minimal: field yang berubah)
  - aksi: "create" | "update" | "submit" | "request_revision" | "admin_override"

/settings/deadline               // dokumen tunggal, dikelola Admin Labkesda
  - batasInputHari: number        // X — §6.1
  - satuanBatasInput: "kalender" | "kerja"
  - batasRevisiHari: number       // Y — §6.2
  - diubahOleh: uid
  - diubahPada: timestamp
```

**Kenapa `examTypes` jadi koleksi terpisah (bukan hardcode di app):** agar Admin Labkesda bisa menambah/mengubah jenis pemeriksaan di masa depan tanpa perlu update aplikasi Flutter — cukup lewat dashboard admin.

**Kenapa `hasil` berupa map, bukan sub-collection:** karena 38 field selalu diakses bersamaan sebagai satu form/satu laporan, map jauh lebih efisien (1 read = 1 laporan lengkap) dibanding 38 dokumen terpisah.

**Kenapa `settings/deadline` jadi dokumen terpisah:** agar batas waktu input (`batasInputHari`) dan batas waktu revisi (`batasRevisiHari`) bisa diubah Admin Labkesda kapan saja dari UI, tanpa perlu deploy ulang aplikasi. Nilai ini dibaca oleh client (untuk menampilkan status overdue) **dan** oleh Firestore Security Rules (untuk menegakkan kunci revisi saat ada percobaan edit) — keduanya menghitung status secara real-time dari nilai ini + timestamp laporan, tanpa Cloud Function (§6.3).

---

## 8. Keamanan (Firestore Security Rules) — Prinsip

- Petugas puskesmas **hanya bisa baca/tulis** dokumen `laporan` milik `puskesmasId` sendiri.
- Petugas puskesmas **tidak bisa** membaca laporan puskesmas lain (privasi antar-puskesmas, walau data agregat, tetap dijaga).
- Petugas puskesmas **tidak bisa menulis** ke `laporan` yang statusnya sudah lewat batas revisi — rules menghitung langsung: `request.time < resource.data.disubmitPada + duration.value(batasRevisiHari, 'd')` (nilai `batasRevisiHari` dibaca dari `/settings/deadline` di dalam rules via `get()`).
- Admin Labkesda bisa baca-semua, tulis-semua laporan (untuk fitur request revision/override), dan satu-satunya role yang boleh menulis ke `/settings/deadline`.
- Hanya ada 2 role (`puskesmas`, `admin`) — tidak ada tingkatan superadmin terpisah, sehingga rules lebih sederhana: cukup 1 percabangan `if role == 'admin'` untuk semua kewenangan admin.
- **Role disimpan sebagai field di dokumen `/users/{uid}`** (bukan custom claims Firebase Auth) — karena custom claims butuh Cloud Function untuk di-set, dan project ini memakai paket Spark/gratis tanpa Cloud Functions (§6.3). Security rules membaca role via `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role`. Trade-off: setiap rules check butuh 1 extra document read, tapi untuk skala aplikasi ini (35 puskesmas) dampaknya tidak signifikan dan masih jauh di bawah free tier.
- Field `status`, `puskesmasId`, `tahun`, `bulan` tidak boleh diubah oleh role puskesmas setelah dokumen dibuat (immutable identifier fields).

---

## 9. Non-Functional Requirements

| Aspek | Requirement |
|---|---|
| Offline support | Firestore offline persistence diaktifkan (built-in) — petugas tetap bisa isi form saat koneksi lemah, sync otomatis saat online |
| Platform | **Dua target build dari 1 codebase Flutter:** (1) Android & iOS untuk Petugas Puskesmas, (2) **Flutter Web** untuk Admin Labkesda (dikonfirmasi, wajib — bukan opsional) |
| Historis data lama | **Tidak ada migrasi** data 2025/sebelumnya (dikonfirmasi: sistem baru mulai bersih dari periode berjalan saat go-live) |
| Export | Format Excel (.xlsx) hasil export harus 1:1 kompatibel dengan struktur existing (nama sheet, header, urutan kolom, baris JUMLAH) |
| Skala | ~35 puskesmas, ~12 laporan/tahun/puskesmas → total data sangat kecil untuk Firestore (jauh di bawah free tier bahkan setelah bertahun-tahun) |
| Bahasa | Bahasa Indonesia, istilah medis sesuai istilah existing (jangan diterjemahkan) |
| Aksesibilitas | Form angka harus pakai numeric keyboard, validasi angka non-negatif |

---

## 10. Tech Stack

- **Frontend:** Flutter 3.44.3 (pure Flutter — tanpa backend server custom)
- **State management:** direkomendasikan **Riverpod** (ringan, testable, cocok untuk skala app ini) — bisa diganti Provider/Bloc sesuai preferensi tim
- **Backend/DB:** Firebase — **Paket Spark (gratis)**
  - **Firebase Auth** (email/password)
  - **Cloud Firestore** (database utama)
  - ~~Cloud Functions~~ — **tidak dipakai** (butuh paket Blaze). Fungsinya digantikan: role via field Firestore + rules `get()` (§8), status overdue/lock via kalkulasi client & rules (§6.3), pembuatan akun via **secondary Firebase App instance** (lihat di bawah).
  - **Firebase Storage** (opsional — simpan file Excel hasil export, atau backup; tetap gratis di Spark sampai batas kuota)
  - **Firebase Hosting** — **wajib** (dikonfirmasi), untuk deploy build Flutter Web Admin Labkesda — gratis di Spark sampai batas kuota (lebih dari cukup untuk 1 aplikasi internal)
- **Cara Admin membuat akun puskesmas baru tanpa Cloud Function:** gunakan **secondary `FirebaseApp` instance** di Flutter — Admin Labkesda tetap login di app instance utama, lalu aplikasi membuat `FirebaseApp` kedua sementara (`Firebase.initializeApp(name: 'secondary', options: ...)`), memanggil `createUserWithEmailAndPassword` di instance kedua itu (supaya tidak menggantikan sesi login admin), lalu langsung `signOut` dari instance kedua dan `deleteApp`. Setelah user Auth berhasil dibuat, tulis dokumen `/users/{uid}` dengan `role: 'puskesmas'` dan `puskesmasId` terkait langsung dari client (diizinkan oleh rules karena dilakukan oleh admin yang sudah login).
- **Excel generation (di Flutter client):** package `excel` atau `syncfusion_flutter_xlsio` (Syncfusion punya free community license untuk kebutuhan kecil — perlu dicek syaratnya)
- **Routing:** `go_router`
- **Form & validasi:** `flutter_form_builder` atau native `Form`/`TextFormField`
- **Responsive layout:** karena 1 codebase melayani mobile (petugas) dan web (admin) dengan kebutuhan UI berbeda (form sederhana vs tabel rekap lebar 38 kolom), gunakan `LayoutBuilder`/breakpoint pattern Flutter standar, dan pertimbangkan package seperti `responsive_framework` untuk mempercepat penyesuaian layout desktop-width di dashboard Admin.

---

## 11. Struktur Project Flutter (usulan)

```
lib/
 ├── main.dart
 ├── app/
 │    ├── router.dart
 │    └── theme.dart
 ├── core/
 │    ├── constants/
 │    ├── services/           // firebase_auth_service, firestore_service, excel_export_service
 │    └── utils/
 ├── features/
 │    ├── auth/
 │    │    ├── login_screen.dart
 │    │    └── forgot_password_screen.dart
 │    ├── puskesmas_dashboard/
 │    │    ├── dashboard_screen.dart
 │    │    ├── form_laporan_screen.dart
 │    │    ├── histori_laporan_screen.dart
 │    │    └── widgets/
 │    ├── labkesda_dashboard/
 │    │    ├── dashboard_screen.dart
 │    │    ├── rekap_table_screen.dart
 │    │    ├── monitoring_status_screen.dart
 │    │    ├── master_data_screen.dart
 │    │    └── widgets/
 │    └── shared/
 ├── models/
 │    ├── laporan_model.dart
 │    ├── puskesmas_model.dart
 │    ├── exam_type_model.dart
 │    └── user_model.dart
 └── providers/                // riverpod providers
```

**Catatan:** karena `puskesmas_dashboard/` (mobile) dan `labkesda_dashboard/` (web) melayani platform berbeda, keduanya tetap 1 codebase Flutter (bukan 2 project terpisah) — routing di `router.dart` yang menentukan flow mana yang dimuat berdasarkan role hasil login, dan `theme.dart`/widget di masing-masing folder disesuaikan agar layout admin nyaman di lebar layar desktop (khususnya untuk tabel rekap 38 kolom), sementara layout puskesmas tetap dioptimalkan untuk layar mobile.

---

## 12. Rencana Pembangunan Step-by-Step

### Fase 0 — Persiapan (1-2 hari)
1. Buat project Firebase baru (**paket Spark/gratis**) → aktifkan Authentication (Email/Password), Firestore, Storage (opsional), **Hosting** (untuk web). Tidak perlu upgrade Blaze / kartu kredit.
2. Buat project Flutter: `flutter create labkesda_app`, set Flutter version ke 3.44.3 (`flutter --version` untuk verifikasi environment). Aktifkan target web: `flutter config --enable-web` (biasanya sudah default aktif di versi terbaru, tinggal verifikasi `flutter devices` menampilkan Chrome).
3. Tambahkan dependencies inti: `firebase_core`, `firebase_auth`, `cloud_firestore`, `go_router`, `flutter_riverpod`, `excel` (atau syncfusion), `intl`.
4. Konfigurasi `flutterfire configure` untuk hubungkan project Flutter ke Firebase — **pilih platform Android, iOS, dan Web** (ketiganya dibutuhkan, dikonfirmasi).
5. Setup struktur folder sesuai §11, dengan pemisahan yang jelas antara flow `puskesmas_dashboard` (mobile-first) dan `labkesda_dashboard` (web-first, layout lebar).

### Fase 1 — Master Data & Seed (1 hari)
1. Buat script Node.js sekali-jalan (pakai Firebase Admin SDK, dijalankan lokal — bukan Cloud Function) untuk **seed data**: 35 puskesmas (sesuai daftar dari Excel) ke koleksi `/puskesmas`, dan 38 jenis pemeriksaan (sesuai Lampiran A) ke koleksi `/examTypes` dengan urutan sesuai kolom Excel.
2. Buat akun awal: 1 akun Admin Labkesda (role tunggal, tidak ada super admin terpisah) — dibuat manual via Firebase Console (Authentication → Add user), lalu tulis dokumen `/users/{uid}` dengan `role: "admin"` via script yang sama.
3. Seed dokumen `/settings/deadline` dengan nilai default awal (misal `batasInputHari: 10`, `satuanBatasInput: "kalender"`, `batasRevisiHari: 10`) — nantinya bisa diubah Admin Labkesda kapan saja dari dashboard.

### Fase 2 — Autentikasi & Role (2-3 hari)
1. Implementasi login screen (email/password) dengan `firebase_auth`.
2. Implementasi mekanisme **role via Firestore** (§8): setelah login, baca dokumen `/users/{uid}` untuk dapatkan `role` dan `puskesmasId`, simpan di Riverpod state, dipakai untuk redirect & guard routing.
3. Implementasi routing berbasis role (redirect otomatis ke Dashboard Puskesmas atau Dashboard Labkesda setelah login) via `go_router` + Riverpod auth state.
4. Fitur lupa password (reset via email Firebase Auth).

### Fase 3 — Firestore Security Rules (1-2 hari, dikerjakan paralel)
1. Tulis rules sesuai §8 — role puskesmas hanya akses laporan sendiri, admin akses semua.
2. Uji rules dengan Firebase Emulator Suite (`firebase emulators:start`) sebelum deploy ke production.

### Fase 4 — Dashboard & Form Puskesmas (4-6 hari)
1. Dashboard: tampilkan status laporan bulan berjalan + daftar bulan-bulan sebelumnya (query `/laporan` where `puskesmasId == myId`).
2. Form input 38 jenis pemeriksaan:
   - Render field dinamis dari `/examTypes` (bukan hardcode), urut sesuai `urutan`.
   - Search box di atas form untuk filter jenis pemeriksaan (scroll-to atau filter list).
   - Validasi: angka non-negatif, default 0.
   - Tombol "Simpan Draft" (write status=draft) dan "Submit" (write status=submitted + timestamp).
3. Fitur update/revisi: buka laporan lama, jika status masih editable → tampilkan form sama dengan data ter-load, simpan sebagai update + catat ke sub-collection `histori`.
4. Fitur pencarian data (histori laporan): search/filter by bulan, tahun, status.
5. Unit test untuk validasi form & logic status transition.

### Fase 5 — Dashboard Admin Labkesda (5-7 hari)
1. Monitoring status: grid/tabel 35 puskesmas x 12 bulan dengan color-coded status (query semua laporan tahun berjalan, group by puskesmas).
2. Rekap tabel gabungan: tabel per bulan (baris=puskesmas, kolom=38 jenis pemeriksaan) + baris JUMLAH dihitung di client (sum semua row) — tampilkan mirip layout Excel existing.
3. Rekap semester/tahunan: agregasi (sum) dari laporan bulanan yang sudah submitted.
4. Fitur "Minta Revisi" — update status laporan ke `revision_requested` + catatanRevisi wajib diisi, trigger (opsional) notifikasi ke puskesmas terkait.
5. Master data management: CRUD puskesmas & jenis pemeriksaan.
6. Manajemen akun: Admin Labkesda bisa membuat akun petugas puskesmas baru langsung dari dashboard, memakai teknik **secondary Firebase App instance** (§10) — tanpa Cloud Function.
7. Audit trail viewer: baca sub-collection `histori` per laporan.
8. **Halaman pengaturan batas waktu** — form untuk set `batasInputHari` (X) dan `batasRevisiHari` (Y) + satuan (kalender/kerja), tulis ke `/settings/deadline`.
9. **Kalkulasi status overdue & lock dilakukan on-the-fly** (§6.3) — tidak ada scheduled Cloud Function di paket Spark. Dashboard monitoring menghitung status "Terlambat" langsung di client saat query dijalankan (bandingkan tanggal sekarang vs `/settings/deadline`), dan Firestore Rules yang menegakkan penguncian revisi saat ada percobaan edit dari puskesmas.

### Fase 6 — Export Excel (3-4 hari)
1. Riset & pilih package (`excel` vs `syncfusion_flutter_xlsio`) berdasarkan kebutuhan formatting persis (styling header, merge cell, dsb — cek kompleksitas format existing yang butuh **merge cell** untuk judul & sub-header, jadi kemungkinan besar butuh package yang support merge cell + styling, seperti Syncfusion).
2. Implementasi generate file .xlsx dengan struktur identik file existing (per sheet bulan, sheet semester, baris JUMLAH via formula atau hasil hitung).
3. Simpan/download file (mobile: `path_provider` + share; web: trigger browser download).
4. QA: bandingkan output export dengan file Excel existing untuk memastikan 100% konsisten (nama sheet, urutan kolom, format header).

### Fase 7 — Notifikasi & Polish (2-3 hari, opsional tapi disarankan)
1. Reminder pengingat laporan belum diisi (local notification / in-app badge, cukup tanpa push notification server dulu untuk MVP).
2. Grafik ringkas untuk Admin Labkesda (pakai `fl_chart` atau `syncfusion_flutter_charts`).
3. Polish UI/UX, dark mode (opsional), empty states, loading states, error handling menyeluruh.

### Fase 8 — Testing & Deployment (2-4 hari)
1. **Tidak ada migrasi data historis** (dikonfirmasi) — sistem mulai bersih dari periode berjalan saat go-live; data Excel lama tetap disimpan sebagai arsip terpisah di luar sistem, tidak perlu diimpor.
2. Deploy build web Admin Labkesda: `flutter build web` → `firebase deploy --only hosting`.
3. User Acceptance Testing (UAT) bersama beberapa petugas puskesmas & Admin Labkesda (idealnya minimal 1-2 minggu masa uji paralel dengan proses manual, sebelum full cut-over).
4. Setup Firebase App Distribution / TestFlight untuk beta testing versi mobile.
5. Release ke Play Store / App Store (atau internal distribution jika tidak perlu publik) untuk versi Petugas Puskesmas; bagikan URL Hosting untuk versi Admin Labkesda.
6. Training singkat untuk petugas puskesmas & admin Labkesda.

**Estimasi total:** ±5-7 minggu kerja untuk 1 developer (bisa lebih cepat dengan 2 developer paralel: 1 fokus Fase 4, 1 fokus Fase 5-6).

---

## 13. Keputusan Final (Sudah Dikonfirmasi)

Semua poin berikut sudah dikonfirmasi dan menjadi acuan tetap PRD ini — tidak ada lagi asumsi terbuka di area ini:

| # | Topik | Keputusan |
|---|---|---|
| 1 | Aturan approval | Pakai mekanisme **"Minta Revisi"** — tidak ada approval manual wajib per laporan (§6, §4.2) |
| 2 | Satuan batas waktu | **Default hari kalender** untuk `batasInputHari` & `batasRevisiHari`; opsi hari kerja disediakan di data model tapi tidak diimplementasikan di MVP (§6.1) |
| 3 | Akun puskesmas | **1 puskesmas = 1 akun**, tidak ada multi-user per puskesmas di MVP (§3) |
| 4 | Data historis | **Tidak dimigrasi** — sistem baru mulai bersih dari periode berjalan saat go-live (§9, Fase 8) |
| 5 | Platform Admin Labkesda | **Build Flutter Web**, dideploy via Firebase Hosting (§9, §10, Fase 0 & 8) |
| 6 | Daftar jenis pemeriksaan | **Fleksibel** — CRUD penuh oleh Admin Labkesda melalui dashboard, bagian dari fitur inti MVP (§5.2, §7) |
| 7 | Paket Firebase | **Spark (gratis, tanpa Cloud Functions/Blaze)** — role via Firestore doc, overdue/lock dihitung on-the-fly, admin create user via secondary app instance (§6.3, §10) |

Dengan semua keputusan ini terkunci, PRD sudah cukup lengkap untuk mulai eksekusi Fase 0. Jika ada perubahan kebijakan di kemudian hari (misalnya kelak butuh multi-user per puskesmas, atau migrasi data lama ternyata diperlukan), area tersebut sudah dirancang cukup modular (role-based access, collection `settings` terpisah) untuk diperluas tanpa perombakan besar.

---

## Lampiran A — 38 Jenis Pemeriksaan (dari data existing)

1. Darah Rutin
2. HB Stik
3. Leucosit
4. Trombosit
5. Hematokrit
6. Trigliserida
7. Kholesterol Total
8. Kholesterol Stik
9. SGOT
10. SGPT
11. Ureum
12. Creatin
13. Asam Urat
14. Asam Urat Stik
15. Glukosa Puasa
16. Glukosa Sewaktu
17. Glukosa 2 Jam PP
18. Glukosa Stik
19. HIV
20. Sypilis
21. HBSAg
22. Viral Load
23. Sputum
24. Sekret Vagina
25. Sekret Uretra
26. TCM
27. Golongan Darah
28. Plano Test
29. Widal
30. Covid
31. Reduksi Urine
32. Sedimen Urine
33. Protein Urine
34. Urine Rutin
35. Dengue IgG, IgM (Rapid)
36. Malaria
37. Dengue NSI
38. Feaces Rutin
