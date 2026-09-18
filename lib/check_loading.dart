import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    final content = file.readAsStringSync();
    if (content.contains('_isLoading = true')) {
      final trueCount = RegExp(r'_isLoading = true').allMatches(content).length;
      final falseCount = RegExp(r'_isLoading = false').allMatches(content).length;
      
      if (falseCount < trueCount) {
        print('Warning: ${file.path.split(Platform.pathSeparator).last} missing false (true: $trueCount, false: $falseCount)');
      }
      if (!content.contains('finally')) {
        print('Warning: ${file.path.split(Platform.pathSeparator).last} has _isLoading but NO finally block');
      }
    }
  }
}
