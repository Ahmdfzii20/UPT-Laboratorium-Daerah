import 'package:cloud_firestore/cloud_firestore.dart';

class DeadlineModel {
  final int batasInputHari;

  /// Dipertahankan untuk kompatibilitas data Firestore lama.
  final String satuanBatasInput;
  final int batasRevisiHari;
  final String? diubahOleh;
  final DateTime? diubahPada;

  const DeadlineModel({
    this.batasInputHari = 10,
    this.satuanBatasInput = 'kalender',
    this.batasRevisiHari = 10,
    this.diubahOleh,
    this.diubahPada,
  });

  factory DeadlineModel.fromFirestore(Map<String, dynamic> data) {
    return DeadlineModel(
      batasInputHari: (data['batasInputHari'] as num?)?.toInt() ?? 10,
      satuanBatasInput: 'kalender',
      batasRevisiHari: (data['batasRevisiHari'] as num?)?.toInt() ?? 10,
      diubahOleh: data['diubahOleh'] as String?,
      diubahPada: (data['diubahPada'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'batasInputHari': batasInputHari,
      'satuanBatasInput': 'kalender',
      'batasRevisiHari': batasRevisiHari,
      'diubahOleh': diubahOleh,
      'diubahPada': diubahPada == null ? null : Timestamp.fromDate(diubahPada!),
    };
  }

  DeadlineModel copyWith({
    int? batasInputHari,
    String? satuanBatasInput,
    int? batasRevisiHari,
    String? diubahOleh,
    DateTime? diubahPada,
  }) {
    return DeadlineModel(
      batasInputHari: batasInputHari ?? this.batasInputHari,
      satuanBatasInput: 'kalender',
      batasRevisiHari: batasRevisiHari ?? this.batasRevisiHari,
      diubahOleh: diubahOleh ?? this.diubahOleh,
      diubahPada: diubahPada ?? this.diubahPada,
    );
  }
}
