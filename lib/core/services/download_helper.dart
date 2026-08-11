import 'dart:typed_data';

export 'download_helper_io.dart'
    if (dart.library.html) 'download_helper_web.dart';

/// Menyimpan/mendownload bytes sebagai file .xlsx.
/// - Web: memicu download browser.
/// - Mobile/desktop: menyimpan ke direktori temp lalu membuka share sheet.
Future<void> downloadFile(Uint8List bytes, String filename) async {
  throw UnimplementedError();
}
