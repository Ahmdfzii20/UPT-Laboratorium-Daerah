class ExamTypeModel {
  final String id;
  final String nama;
  final int urutan;
  final bool aktif;
  final String kategori;

  const ExamTypeModel({
    required this.id,
    required this.nama,
    this.urutan = 0,
    this.aktif = true,
    this.kategori = '',
  });

  factory ExamTypeModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ExamTypeModel(
      id: id,
      nama: data['nama'] as String? ?? '',
      urutan: (data['urutan'] as num?)?.toInt() ?? 0,
      aktif: data['aktif'] as bool? ?? true,
      kategori: data['kategori'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'urutan': urutan,
      'aktif': aktif,
      'kategori': kategori,
    };
  }
}
