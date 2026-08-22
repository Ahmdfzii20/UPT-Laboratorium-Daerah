import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../models/deadline_model.dart';
import '../../models/exam_type_model.dart';
import '../../models/laporan_model.dart';
import '../../models/puskesmas_model.dart';
import '../../models/user_model.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // -------------------------------------------------------------------------
  // Referensi koleksi
  // -------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> get puskesmasRef =>
      _db.collection('puskesmas');

  CollectionReference<Map<String, dynamic>> get examTypesRef =>
      _db.collection('examTypes');

  CollectionReference<Map<String, dynamic>> get usersRef => _db.collection('users');

  CollectionReference<Map<String, dynamic>> get laporanRef =>
      _db.collection('laporan');

  DocumentReference<Map<String, dynamic>> get settingsDeadlineRef =>
      _db.collection('settings').doc('deadline');

  // -------------------------------------------------------------------------
  // Master data
  // -------------------------------------------------------------------------

  Stream<List<PuskesmasModel>> streamPuskesmas() {
    return puskesmasRef
        .orderBy('urutan')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PuskesmasModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Stream<List<ExamTypeModel>> streamExamTypes() {
    return examTypesRef
        .orderBy('urutan')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ExamTypeModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<void> simpanPuskesmas(PuskesmasModel p, {String? docId}) async {
    if (docId == null) {
      await puskesmasRef.add(p.toFirestore());
    } else {
      await puskesmasRef.doc(docId).set(p.toFirestore());
    }
  }

  Future<void> simpanExamType(ExamTypeModel e, {String? docId}) async {
    if (docId == null) {
      await examTypesRef.add(e.toFirestore());
    } else {
      await examTypesRef.doc(docId).set(e.toFirestore());
    }
  }

  Future<void> hapusPuskesmas(String id) =>
      puskesmasRef.doc(id).delete();

  Future<void> hapusExamType(String id) =>
      examTypesRef.doc(id).delete();

  // -------------------------------------------------------------------------
  // Laporan
  // -------------------------------------------------------------------------

  Stream<List<LaporanModel>> streamLaporanByPuskesmas(String puskesmasId) {
    return laporanRef
        .where('puskesmasId', isEqualTo: puskesmasId)
        .orderBy('tahun', descending: true)
        .orderBy('bulan', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LaporanModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Stream<List<LaporanModel>> streamSemuaLaporan({int? tahun}) {
    var query = laporanRef as Query<Map<String, dynamic>>;
    if (tahun != null) {
      query = query.where('tahun', isEqualTo: tahun);
    }
    return query
        .orderBy('tahun', descending: true)
        .orderBy('bulan', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LaporanModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<LaporanModel?> getLaporan(String puskesmasId, int tahun, int bulan) async {
    final query = await laporanRef
        .where('puskesmasId', isEqualTo: puskesmasId)
        .where('tahun', isEqualTo: tahun)
        .where('bulan', isEqualTo: bulan)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final d = query.docs.first;
    return LaporanModel.fromFirestore(d.id, d.data());
  }

  Future<LaporanModel> getLaporanById(String id) async {
    final d = await laporanRef.doc(id).get();
    if (!d.exists) {
      throw Exception('Laporan tidak ditemukan.');
    }
    return LaporanModel.fromFirestore(d.id, d.data()!);
  }

  String generateLaporanId(String puskesmasId, int tahun, int bulan) =>
      '${puskesmasId}_${tahun}_$bulan';

  /// Menyimpan laporan baru (create) beserta histori aksi.
  Future<void> createLaporan(LaporanModel laporan, String uid) async {
    final ref = laporanRef.doc(laporan.id);
    await ref.set(laporan.toFirestore());
    await catatHistori(
      laporanId: laporan.id,
      uid: uid,
      aksi: 'create',
      perubahan: {'status': laporan.status.value},
    );
  }

  /// Mengupdate laporan yang sudah ada + mencatat histori (audit trail).
  Future<void> updateLaporan(
    LaporanModel laporan,
    String uid, {
    String? aksi = 'update',
  }) async {
    final ref = laporanRef.doc(laporan.id);
    await ref.set(laporan.toFirestore());
    await catatHistori(
      laporanId: laporan.id,
      uid: uid,
      aksi: aksi ?? 'update',
      perubahan: {
        'status': laporan.status.value,
        'hasil': laporan.hasil,
      },
    );
  }

  Future<void> catatHistori({
    required String laporanId,
    required String uid,
    required String aksi,
    required Map<String, dynamic> perubahan,
  }) async {
    await laporanRef
        .doc(laporanId)
        .collection('histori')
        .add({
      'diubahOleh': uid,
      'diubahPada': FieldValue.serverTimestamp(),
      'aksi': aksi,
      'perubahan': perubahan,
    });
  }

  Stream<List<Map<String, dynamic>>> streamHistori(String laporanId) {
    return laporanRef
        .doc(laporanId)
        .collection('histori')
        .orderBy('diubahPada', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {
          'id': d.id,
          ...d.data(),
          'diubahPada': (d.data()['diubahPada'] as Timestamp?)?.toDate(),
        })
            .toList());
  }

  // -------------------------------------------------------------------------
  // User & akun
  // -------------------------------------------------------------------------

  Stream<List<UserModel>> streamUsers() {
    return usersRef
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<UserModel?> getUserById(String uid) async {
    final d = await usersRef.doc(uid).get();
    if (!d.exists) return null;
    return UserModel.fromFirestore(uid, d.data()!);
  }

  Future<void> simpanUser(UserModel user) async {
    await usersRef.doc(user.uid).set(user.toFirestore());
  }

  Future<void> nonaktifkanUser(String uid, bool aktif) async {
    await usersRef.doc(uid).update({'aktif': aktif});
  }

  /// Membuat akun petugas puskesmas baru memakai teknik secondary Firebase App
  /// instance (§10 PRD) — tanpa Cloud Function, sesi admin tidak terganggu.
  Future<UserCredential> buatAkunPuskesmas({
    required String email,
    required String password,
    required String puskesmasId,
    required String nama,
  }) async {
    final options = Firebase.app().options;
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary',
      options: options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      try {
        await usersRef.doc(cred.user!.uid).set({
          'email': email,
          'role': 'puskesmas',
          'puskesmasId': puskesmasId,
          'nama': nama,
          'aktif': true,
        });
      } catch (_) {
        // Jangan meninggalkan akun Auth tanpa profil Firestore.
        await cred.user?.delete();
        rethrow;
      }
      await secondaryAuth.signOut();
      return cred;
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // -------------------------------------------------------------------------
  // Settings deadline
  // -------------------------------------------------------------------------

  Stream<DeadlineModel> streamDeadline() {
    return settingsDeadlineRef.snapshots().map((snap) {
      if (!snap.exists) return const DeadlineModel();
      return DeadlineModel.fromFirestore(snap.data()!);
    });
  }

  Future<void> simpanDeadline(DeadlineModel d, String uid) async {
    await settingsDeadlineRef.set(
      d.copyWith(diubahOleh: uid, diubahPada: DateTime.now()).toFirestore(),
    );
  }
}
