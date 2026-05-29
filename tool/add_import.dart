import 'dart:io';

void main() async {
  final dir = Directory('lib');
  final files = await dir.list(recursive: true).toList();
  
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = await file.readAsString();
      if (content.contains('AppColors') && !content.contains('app_colors.dart')) {
        // Find the first import and add it before
        int index = content.indexOf('import');
        if (index != -1) {
          content = "${content.substring(0, index)}import 'package:chiabill/theme/app_colors.dart';\n${content.substring(index)}";
          await file.writeAsString(content);
          print('Added import to \${file.path}');
        }
      }
    }
  }
}
