import 'dart:io';

void main() async {
  final file = File('lib/screens/profile/profile_screen.dart');
  if (await file.exists()) {
    String content = await file.readAsString();
    content = content.replaceAll('Colors.orange', 'AppColors.primary');
    await file.writeAsString(content);
    print('Replaced Colors.orange in profile_screen.dart');
  }
}
