import 'dart:io';

void main() async {
  final dir = Directory('lib');
  if (!await dir.exists()) return;

  final files = await dir.list(recursive: true).toList();
  for (var file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = await file.readAsString();
      
      // We want to replace all occurrences of Colors.lightGreen
      // But handle the shades properly.
      // Colors.lightGreen.shade700 -> Color(0xFF047857) (A bit darker)
      // Colors.lightGreen.shade400 -> Color(0xFF34D399)
      // Colors.lightGreen.shade100 -> Color(0xFFD1FAE5)
      // Colors.lightGreen.shade50 -> Color(0xFFECFDF5)
      // Colors.lightGreen -> const Color(0xFF10B981)
      
      content = content.replaceAll('Colors.lightGreen.shade700', 'const Color(0xFF047857)');
      content = content.replaceAll('Colors.lightGreen.shade800', 'const Color(0xFF065F46)');
      content = content.replaceAll('Colors.lightGreen.shade400', 'const Color(0xFF34D399)');
      content = content.replaceAll('Colors.lightGreen.shade300', 'const Color(0xFF6EE7B7)');
      content = content.replaceAll('Colors.lightGreen.shade200', 'const Color(0xFFA7F3D0)');
      content = content.replaceAll('Colors.lightGreen.shade100', 'const Color(0xFFD1FAE5)');
      content = content.replaceAll('Colors.lightGreen.shade50', 'const Color(0xFFECFDF5)');
      content = content.replaceAll('Colors.lightGreen[700]', 'const Color(0xFF047857)');
      content = content.replaceAll('Colors.lightGreen[100]', 'const Color(0xFFD1FAE5)');
      content = content.replaceAll('Colors.lightGreen', 'const Color(0xFF10B981)');

      await file.writeAsString(content);
      print('Processed ${file.path}');
    }
  }
}
