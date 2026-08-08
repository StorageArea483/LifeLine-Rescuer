import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:life_line_rescuer/config/environment.dart';
import 'package:open_filex/open_filex.dart';

class AppwriteService {
  static Future<void> downloadGuide() async {
    final client = Client()
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId);
    final storage = Storage(client);

    final directory = await _getDownloadsDirectory();
    final file = File(
      '${directory.path}/Psychological First Aid Guidelines.pdf',
    );

    // If it's already downloaded, just open it instead of throwing.
    if (await file.exists()) {
      await _openFile(file.path);
      return;
    }

    final bytes = await storage.getFileDownload(
      bucketId: '69f180590004b2f6de27',
      fileId: '6a363302000f7b5712ea',
    );
    await file.writeAsBytes(bytes);

    await _openFile(file.path);
  }

  static Future<Directory> _getDownloadsDirectory() async {
    const downloadsPath = '/storage/emulated/0/Download';
    final dir = Directory(downloadsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open file: ${result.message}');
    }
  }
}
