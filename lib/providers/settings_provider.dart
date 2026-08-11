import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/firestore_service.dart';
import '../models/deadline_model.dart';

/// Nilai batas waktu input & revisi dari /settings/deadline (dapat diubah admin).
final deadlineProvider = StreamProvider<DeadlineModel>((ref) {
  return FirestoreService.instance.streamDeadline();
});
