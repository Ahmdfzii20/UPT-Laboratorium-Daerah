class PuskesmasModel {
  final String id;
  final String nama;
  final String kode;
  final String kecamatan;
  final bool aktif;
  final int urutan;

  const PuskesmasModel({
    required this.id,
    required this.nama,
    this.kode = '',
    this.kecamatan = '',
    this.aktif = true,
    this.urutan = 0,
  });

  factory PuskesmasModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PuskesmasModel(
      id: id,
      nama: data['nama'] as String? ?? '',
      kode: data['kode'] as String? ?? '',
      kecamatan: data['kecamatan'] as String? ?? '',
      aktif: data['aktif'] as bool? ?? true,
      urutan: (data['urutan'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'kode': kode,
      'kecamatan': kecamatan,
      'aktif': aktif,
      'urutan': urutan,
    };
  }
}
