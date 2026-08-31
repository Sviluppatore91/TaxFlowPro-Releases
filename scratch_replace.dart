import 'dart:io';
import 'dart:convert';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content;
    try {
      content = file.readAsStringSync(encoding: utf8);
    } catch (e) {
      try {
        content = file.readAsStringSync(encoding: latin1);
      } catch (e) {
        print("Failed to read ${file.path}");
        continue;
      }
    }
    
    String original = content;

    bool hasCurrencyUtils = content.contains("import '../utils/currency_utils.dart';") ||
        content.contains("import 'utils/currency_utils.dart';") ||
        content.contains("import '../../utils/currency_utils.dart';");

    // 1. replace: '${double.tryParse(p['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} €'
    content = content.replaceAllMapped(
      RegExp(r"'\$\{double\.tryParse\(([^)]+)\)\?\.toStringAsFixed\(2\) \?\? '0\.00'\} €'"),
      (m) => "CurrencyUtils.formatEuro(CurrencyUtils.parseCurrency(${m.group(1)}))",
    );
    content = content.replaceAllMapped(
      RegExp(r"'\$\{double\.tryParse\(([^)]+)\)\?\.toStringAsFixed\(2\) \?\? '0\.00'\}'"),
      (m) => "CurrencyUtils.formatUI(CurrencyUtils.parseCurrency(${m.group(1)}))",
    );

    // 2. '€ ${amount.toStringAsFixed(2)}' -> CurrencyUtils.formatEuro(amount)
    content = content.replaceAllMapped(
      RegExp(r"'€ \$\{([^}]+)\.toStringAsFixed\(\d+\)\}'"),
      (m) => "CurrencyUtils.formatEuro(${m.group(1)})",
    );
    content = content.replaceAllMapped(
      RegExp(r"'- € \$\{([^}]+)\.toStringAsFixed\(\d+\)\}'"),
      (m) => "'- ' + CurrencyUtils.formatEuro(${m.group(1)})",
    );
    content = content.replaceAllMapped(
      RegExp(r"'€\$\{([^}]+)\.toStringAsFixed\(\d+\)\}'"),
      (m) => "CurrencyUtils.formatEuro(${m.group(1)})",
    );
    content = content.replaceAllMapped(
      RegExp(r"'€\$\{([^}]+)\.toStringAsFixed\(\d+\)\}k'"),
      (m) => "CurrencyUtils.formatEuro(${m.group(1)}) + 'k'",
    );

    // 3. ${pct.toStringAsFixed(0)}
    content = content.replaceAllMapped(
      RegExp(r"\$\{([^}]+)\.toStringAsFixed\((\d+)\)\}"),
      (m) => "\${CurrencyUtils.formatUI(${m.group(1)}, decimals: ${m.group(2)})}",
    );

    if (content != original) {
      if (!hasCurrencyUtils && content.contains('CurrencyUtils')) {
        int depth = file.path.replaceAll('\\', '/').split('/').length - 2;
        if (depth < 0) depth = 0;
        String prefix = List.filled(depth, '../').join('');
        String importStmt = depth == 0
            ? "import 'utils/currency_utils.dart';\n"
            : "import '${prefix}utils/currency_utils.dart';\n";

        int lastImport = content.lastIndexOf(RegExp(r"import '.*';"));
        if (lastImport != -1) {
          int endOfLine = content.indexOf('\n', lastImport);
          content = content.substring(0, endOfLine + 1) + importStmt + content.substring(endOfLine + 1);
        } else {
          content = importStmt + content;
        }
      }

      file.writeAsStringSync(content, encoding: utf8);
      print("Updated ${file.path}");
    }
  }
}
