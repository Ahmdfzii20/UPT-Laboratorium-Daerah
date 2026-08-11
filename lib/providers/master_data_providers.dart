import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/firestore_service.dart';
import '../models/exam_type_model.dart';
import '../models/puskesmas_model.dart';
import '../models/user_model.dart';

/// Daftar master puskesmas (aktif & nonaktif).
final puskesmasListProvider = StreamProvider<List<PuskesmasModel>>((ref) {
  return FirestoreService.instance.streamPuskesmas();
});

/// Daftar master jenis pemeriksaan.
final examTypesProvider = StreamProvider<List<ExamTypeModel>>((ref) {
  return FirestoreService.instance.streamExamTypes();
});

/// Daftar akun user (admin & puskesmas).
final usersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirestoreService.instance.streamUsers();
});
