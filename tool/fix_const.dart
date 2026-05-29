import 'dart:io';

void main() async {
  final dir = Directory('lib');
  if (!await dir.exists()) return;

  final files = await dir.list(recursive: true).toList();
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart') && !file.path.contains('app_colors.dart') && !file.path.contains('app_theme.dart')) {
      List<String> lines = await file.readAsLines();
      bool modified = false;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('AppColors.')) {
          while (lines[i].contains('const ')) {
            lines[i] = lines[i].replaceFirst('const ', '');
            modified = true;
          }
        }
      }
      if (modified) {
        await file.writeAsString(lines.join('\n'));
        print('Processed ${file.path}');
      }
    }
  }
}
