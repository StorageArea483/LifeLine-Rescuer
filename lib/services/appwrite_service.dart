import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:life_line_rescuer/config/environment.dart';
import 'package:path_provider/path_provider.dart';

class AppwriteService {
  static Future<void> downloadGuide() async {
    final client = Client()
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId);

    final storage = Storage(client);

    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/Psychological First Aid Guidelines.pdf',
    );

    // Prevent downloading the same file repeatedly
    if (await file.exists()) {
      throw Exception('Guide already downloaded');
    }

    final bytes = await storage.getFileDownload(
      bucketId: '69f180590004b2f6de27',
      fileId: '6a363302000f7b5712ea',
    );

    await file.writeAsBytes(bytes);
  }
}
