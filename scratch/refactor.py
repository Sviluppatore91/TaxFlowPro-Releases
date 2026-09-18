import os
import re

screens_dir = r"c:\Users\Hp\Documents\Sviluppo\contabile\contabile_app\lib\screens"

# This regex finds Container with margin/padding and decoration containing theme.cardColor
pattern = re.compile(
    r'Container\(\s*'
    r'((?:margin:\s*[^,]+,\s*)?)'
    r'((?:padding:\s*[^,]+,\s*)?)'
    r'decoration:\s*BoxDecoration\(\s*'
    r'color:\s*theme\.cardColor,\s*'
    r'borderRadius:\s*BorderRadius\.circular\([^)]+\),\s*'
    r'border:\s*Border\.all\([^)]+\),\s*'
    r'\),\s*'
    r'(child:\s*(?:Material\(|Column\(|Row\(|InkWell\(|Padding\())',
    re.DOTALL
)

count = 0
for filename in os.listdir(screens_dir):
    if not filename.endswith('.dart'):
        continue
    filepath = os.path.join(screens_dir, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content, num_subs = pattern.subn(
        r'GlassContainer(\n\g<1>\g<2>\g<3>', 
        content
    )
    
    if num_subs > 0:
        if 'package:tax_flow_pro/widgets/glass_container.dart' not in new_content:
            new_content = new_content.replace(
                "import 'package:flutter/material.dart';",
                "import 'package:flutter/material.dart';\nimport 'package:tax_flow_pro/widgets/glass_container.dart';"
            )
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {num_subs} containers in {filename}")
        count += 1

print(f"Total files updated: {count}")
