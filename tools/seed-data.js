/**
 * Seed data awal (Fase 1 PRD) — Sistem Pelaporan Lab Puskesmas → Labkesda.
 *
 * Cara pakai (sekali jalan, di komputer lokal — BUKAN Cloud Functions):
 *   1. npm install firebase-admin
 *   2. Letakkan serviceAccountKey.json (Project Settings → Service accounts →
 *      Generate new private key) di folder yang sama. JANGAN commit ke git.
 *   3. Isi ADMIN_UID dengan UID akun admin pertama (Firebase Console →
 *      Authentication → Add user, lalu salin UID-nya).
 *   4. Lengkapi PUSKESMAS list dengan 35 nama dari file REKAP_PUSKESMAS_THN_2026.xlsx.
 *   5. node tools/seed-data.js
 */
const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ===========================================================================
// GANTI dengan UID akun admin pertama Anda (dari Firebase Console).
// ===========================================================================
const ADMIN_UID = 'PASTE_UID_ADMIN_DI_SINI';

// ===========================================================================
// GANTI dengan 35 nama puskesmas/UPT dari file Excel existing.
// ===========================================================================
const PUSKESMAS = [
  // 'GALANG', 'PAGAR MERBAU', 'DALU SEPULUH', 'UPT.LABKESMAS TK 2 DELI SERDANG',
  // ... isi semua 35 nama dari REKAP_PUSKESMAS_THN_2026.xlsx
];

// 38 jenis pemeriksaan sesuai Lampiran A PRD (urutan = kolom Excel).
const EXAM_TYPES = [
  'DARAH RUTIN', 'HB STIK', 'LEUCOSIT', 'TROMBOSIT', 'HEMATOKRIT',
  'TRIGLISERIDA', 'KHOLESTEROL TOTAL', 'KHOLESTEROL STIK', 'SGOT', 'SGPT',
  'UREUM', 'CREATIN', 'ASAM URAT', 'ASAM URAT STIK', 'GLUKOSA PUASA',
  'GLUKOSA SEWAKTU', 'GLUKOSA 2 JAM PP', 'GLUKOSA STIK', 'HIV', 'SYPILIS',
  'HBSAG', 'VIRAL LOAD', 'SPUTUM', 'SEKRET VAGINA', 'SEKRET URETRA', 'TCM',
  'GOLONGAN DARAH', 'PLANO TEST', 'WIDAL', 'COVID', 'REDUKSI URINE',
  'SEDIMEN URINE', 'PROTEIN URINE', 'URINE RUTIN', 'DENGUE IGG, IGM (RAPID)',
  'MALARIA', 'DENGUE NSI', 'FEACES RUTIN',
];

async function seed() {
  if (ADMIN_UID.startsWith('PASTE_')) {
    console.error('✗ Isi dulu ADMIN_UID di bagian atas tools/seed-data.js');
    process.exit(1);
  }
  if (PUSKESMAS.length === 0) {
    console.error('✗ Isi dulu daftar PUSKESMAS (35 nama) di bagian atas tools/seed-data.js');
    process.exit(1);
  }

  const batch = db.batch();

  batch.set(db.collection('users').doc(ADMIN_UID), {
    email: 'admin@labkesda.go.id', // ganti sesuai email asli akun admin
    role: 'admin',
    nama: 'Admin Labkesda',
    aktif: true,
  });

  PUSKESMAS.forEach((nama, i) => {
    const ref = db.collection('puskesmas').doc();
    batch.set(ref, { nama, aktif: true, urutan: i + 1, kode: '', kecamatan: '' });
  });

  EXAM_TYPES.forEach((nama, i) => {
    const ref = db.collection('examTypes').doc();
    batch.set(ref, { nama, aktif: true, urutan: i + 1, kategori: '' });
  });

  batch.set(db.collection('settings').doc('deadline'), {
    batasInputHari: 10,
    satuanBatasInput: 'kalender',
    batasRevisiHari: 10,
  });

  await batch.commit();
  console.log(`✓ Seed selesai: admin, ${PUSKESMAS.length} puskesmas, ${EXAM_TYPES.length} jenis pemeriksaan, settings/deadline.`);
}

seed().catch((e) => {
  console.error('✗ Seed gagal:', e);
  process.exit(1);
});
