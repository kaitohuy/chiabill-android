import 'dart:io';

void main() async {
  final dir = Directory('lib');
  if (!await dir.exists()) return;

  final files = await dir.list(recursive: true).toList();
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart') && !file.path.contains('app_colors.dart') && !file.path.contains('app_theme.dart') && !file.path.contains('replace_color.dart') && !file.path.contains('main.dart')) {
      String content = await file.readAsString();
      
      bool modified = false;
      
      if (content.contains('Color(0xFF047857)')) {
        content = content.replaceAll('const Color(0xFF047857)', 'AppColors.primaryDark');
        content = content.replaceAll('Color(0xFF047857)', 'AppColors.primaryDark');
        modified = true;
      }
      if (content.contains('Color(0xFF064E3B)')) {
        content = content.replaceAll('const Color(0xFF064E3B)', 'AppColors.primaryDarker');
        content = content.replaceAll('Color(0xFF064E3B)', 'AppColors.primaryDarker');
        modified = true;
      }
      if (content.contains('Color(0xFF065F46)')) {
        content = content.replaceAll('const Color(0xFF065F46)', 'AppColors.primaryDark');
        content = content.replaceAll('Color(0xFF065F46)', 'AppColors.primaryDark');
        modified = true;
      }
      if (content.contains('Color(0xFF34D399)')) {
        content = content.replaceAll('const Color(0xFF34D399)', 'AppColors.primaryLight');
        content = content.replaceAll('Color(0xFF34D399)', 'AppColors.primaryLight');
        modified = true;
      }
      if (content.contains('Color(0xFF6EE7B7)')) {
        content = content.replaceAll('const Color(0xFF6EE7B7)', 'AppColors.primaryLight');
        content = content.replaceAll('Color(0xFF6EE7B7)', 'AppColors.primaryLight');
        modified = true;
      }
      if (content.contains('Color(0xFFA7F3D0)')) {
        content = content.replaceAll('const Color(0xFFA7F3D0)', 'AppColors.primaryLighter');
        content = content.replaceAll('Color(0xFFA7F3D0)', 'AppColors.primaryLighter');
        modified = true;
      }
      if (content.contains('Color(0xFFD1FAE5)')) {
        content = content.replaceAll('const Color(0xFFD1FAE5)', 'AppColors.primaryBackground');
        content = content.replaceAll('Color(0xFFD1FAE5)', 'AppColors.primaryBackground');
        modified = true;
      }
      if (content.contains('Color(0xFFECFDF5)')) {
        content = content.replaceAll('const Color(0xFFECFDF5)', 'AppColors.primaryBackgroundLight');
        content = content.replaceAll('Color(0xFFECFDF5)', 'AppColors.primaryBackgroundLight');
        modified = true;
      }
      if (content.contains('Color(0xFF10B981)')) {
        content = content.replaceAll('const Color(0xFF10B981)', 'AppColors.primary');
        content = content.replaceAll('Color(0xFF10B981)', 'AppColors.primary');
        modified = true;
      }

      if (modified) {
        // Add import if not present
        if (!content.contains('app_colors.dart')) {
          // Find package name. We know it's chiabill.
          content = "import 'package:chiabill/theme/app_colors.dart';\n$content";
        }
        
        // Remove 'const ' before common widgets using colors
        content = content.replaceAll('const TextStyle(', 'TextStyle(');
        content = content.replaceAll('const Icon(', 'Icon(');
        content = content.replaceAll('const BorderSide(', 'BorderSide(');
        content = content.replaceAll('const CircularProgressIndicator(', 'CircularProgressIndicator(');
        content = content.replaceAll('const BoxShadow(', 'BoxShadow(');
        
        await file.writeAsString(content);
        print('Processed ${file.path}');
      }
    }
  }
}
