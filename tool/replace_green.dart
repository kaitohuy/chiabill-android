import 'dart:io';

void main() async {
  final dir = Directory('lib');
  if (!await dir.exists()) return;

  final files = await dir.list(recursive: true).toList();
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart') && !file.path.contains('app_colors.dart') && !file.path.contains('app_theme.dart')) {
      String content = await file.readAsString();
      
      bool modified = false;

      Map<String, String> replacements = {
        'Colors.green[50]': 'AppColors.primaryBackgroundLight',
        'Colors.green.shade50': 'AppColors.primaryBackgroundLight',
        'Colors.green[100]': 'AppColors.primaryBackground',
        'Colors.green.shade100': 'AppColors.primaryBackground',
        'Colors.green[200]': 'AppColors.primaryLight',
        'Colors.green.shade200': 'AppColors.primaryLight',
        'Colors.green': 'AppColors.primary',
      };

      for (var entry in replacements.entries) {
        if (content.contains(entry.key)) {
          content = content.replaceAll(entry.key, entry.value);
          modified = true;
        }
      }

      if (modified) {
        await file.writeAsString(content);
        print('Processed ${file.path}');
      }
    }
  }
}
