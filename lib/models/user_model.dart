class UserModel {
  final String uid;
  final String email;
  final String role; // 'puskesmas' | 'admin'
  final String? puskesmasId;
  final String nama;
  final bool aktif;

  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.puskesmasId,
    required this.nama,
    this.aktif = true,
  });

  bool get isAdmin => role == 'admin';
  bool get isPuskesmas => role == 'puskesmas';

  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'puskesmas',
      puskesmasId: data['puskesmasId'] as String?,
      nama: data['nama'] as String? ?? '',
      aktif: data['aktif'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'puskesmasId': puskesmasId,
      'nama': nama,
      'aktif': aktif,
    };
  }
}
