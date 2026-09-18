import 'package:tax_flow_pro/utils/logger.dart'; // this is just a dummy to avoid errors, actually this will run without pub get if we use simple dart.
import 'dart:io';

void main() {
  var dir = Directory('c:/Users/Hp/Documents/Sviluppo/contabile/contabile_app/lib');
  
  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      if (content.contains('print(')) {
        var lines = content.split('\n');
        var newLines = <String>[];
        var madeChanges = false;
        
        for (var line in lines) {
          if (line.contains('print(')) {
            if (line.toLowerCase().contains('errore')) {
              newLines.add(line.replaceAll('print(', 'appLogger.e('));
            } else {
              newLines.add(line.replaceAll('print(', 'appLogger.i('));
            }
            madeChanges = true;
          } else {
            newLines.add(line);
          }
        }
        
        if (madeChanges) {
          var newContent = newLines.join('\n');
          if (!newContent.contains('logger.dart')) {
            var importStmt = "import 'package:tax_flow_pro/utils/logger.dart';\n";
            if (newContent.contains('import ')) {
              newContent = newContent.replaceFirst('import ', importStmt + 'import ');
            } else {
              newContent = importStmt + newContent;
            }
          }
          entity.writeAsStringSync(newContent);
        }
      }
    }
  }
  print('Done');
}
