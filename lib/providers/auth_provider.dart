import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/firestore_service.dart';
import '../models/user_model.dart';

final authProvider = Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);

/// Stream status login Firebase Auth.
final authStateProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

/// Dokumen /users/{uid} dari pengguna yang sedang login.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return FirestoreService.instance.usersRef.doc(uid).snapshots().map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromFirestore(uid, doc.data()!);
  });
});

/// Pilihan puskesmas untuk formulir pembuatan akun admin.
final daftarPuskesmasAdminProvider = FutureProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
  (ref) async {
    final snap = await FirebaseFirestore.instance
        .collection('puskesmas')
        .orderBy('urutan')
        .get();
    return snap.docs;
  },
);
