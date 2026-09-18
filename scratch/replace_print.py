import os
import re

lib_dir = "c:/Users/Hp/Documents/Sviluppo/contabile/contabile_app/lib"

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            
            if "print(" in content:
                # Replace print with appLogger.i (or e if it says Errore)
                lines = content.split("\n")
                new_lines = []
                made_changes = False
                for line in lines:
                    if "print(" in line:
                        if "errore" in line.lower():
                            new_lines.append(line.replace("print(", "appLogger.e("))
                        else:
                            new_lines.append(line.replace("print(", "appLogger.i("))
                        made_changes = True
                    else:
                        new_lines.append(line)
                
                if made_changes:
                    # check if logger is imported
                    new_content = "\n".join(new_lines)
                    if "logger.dart" not in new_content:
                        import_stmt = "import 'package:tax_flow_pro/utils/logger.dart';\n"
                        # insert after the first import, or at top
                        if "import " in new_content:
                            new_content = new_content.replace("import ", import_stmt + "import ", 1)
                        else:
                            new_content = import_stmt + new_content
                            
                    with open(path, "w", encoding="utf-8") as f:
                        f.write(new_content)
                
print("Done")
