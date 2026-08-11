import 'package:cloud_firestore/cloud_firestore.dart';

enum LaporanStatus {
  draft('draft', 'Draft'),
  submitted('submitted', 'Terkirim'),
  revisionRequested('revision_requested', 'Revisi Diminta');

  const LaporanStatus(this.value, this.label);
  final String value;
  final String label;

  static LaporanStatus fromValue(String? value) {
    return LaporanStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => LaporanStatus.draft,
    );
  }
}

class LaporanModel {
  final String id;
  final String puskesmasId;
  final int tahun;
  final int bulan; // 1-12
  final LaporanStatus status;
  final Map<String, num> hasil; // examTypeId -> jumlah
  final String? dibuatOleh;
  final DateTime? dibuatPada;
  final DateTime? diubahPada;
  final DateTime? disubmitPada;
  final String? catatanRevisi;

  const LaporanModel({
    required this.id,
    required this.puskesmasId,
    required this.tahun,
    required this.bulan,
    required this.status,
    required this.hasil,
    this.dibuatOleh,
    this.dibuatPada,
    this.diubahPada,
    this.disubmitPada,
    this.catatanRevisi,
  });

  String get labelBulanTahun {
    const bulanList = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${bulanList[bulan - 1]} $tahun';
  }

  factory LaporanModel.fromFirestore(String id, Map<String, dynamic> data) {
    final hasilRaw = (data['hasil'] as Map?) ?? const {};
    final hasil = <String, num>{};
    hasilRaw.forEach((k, v) {
      if (v is num) hasil[k.toString()] = v;
      if (v is int) hasil[k.toString()] = v;
    });
    return LaporanModel(
      id: id,
      puskesmasId: data['puskesmasId'] as String? ?? '',
      tahun: (data['tahun'] as num?)?.toInt() ?? DateTime.now().year,
      bulan: (data['bulan'] as num?)?.toInt() ?? 1,
      status: LaporanStatus.fromValue(data['status'] as String?),
      hasil: hasil,
      dibuatOleh: data['dibuatOleh'] as String?,
      dibuatPada: (data['dibuatPada'] as Timestamp?)?.toDate(),
      diubahPada: (data['diubahPada'] as Timestamp?)?.toDate(),
      disubmitPada: (data['disubmitPada'] as Timestamp?)?.toDate(),
      catatanRevisi: data['catatanRevisi'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'puskesmasId': puskesmasId,
      'tahun': tahun,
      'bulan': bulan,
      'status': status.value,
      'hasil': hasil,
      'dibuatOleh': dibuatOleh,
      'dibuatPada': dibuatPada == null ? null : Timestamp.fromDate(dibuatPada!),
      'diubahPada': diubahPada == null ? null : Timestamp.fromDate(diubahPada!),
      'disubmitPada': disubmitPada == null ? null : Timestamp.fromDate(disubmitPada!),
      'catatanRevisi': catatanRevisi,
    };
  }

  LaporanModel copyWith({
    LaporanStatus? status,
    Map<String, num>? hasil,
    DateTime? diubahPada,
    DateTime? disubmitPada,
    String? catatanRevisi,
    bool clearCatatanRevisi = false,
  }) {
    return LaporanModel(
      id: id,
      puskesmasId: puskesmasId,
      tahun: tahun,
      bulan: bulan,
      status: status ?? this.status,
      hasil: hasil ?? this.hasil,
      dibuatOleh: dibuatOleh,
      dibuatPada: dibuatPada,
      diubahPada: diubahPada ?? this.diubahPada,
      disubmitPada: disubmitPada ?? this.disubmitPada,
      catatanRevisi: clearCatatanRevisi ? null : (catatanRevisi ?? this.catatanRevisi),
    );
  }

  num get total {
    num t = 0;
    for (final v in hasil.values) {
      t += v;
    }
    return t;
  }
}
