import os
import re

lib_path = r'C:\Users\Hp\Documents\Sviluppo\contabile\contabile_app\lib'

def replace_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Needs CurrencyUtils imported if not present
    has_currency_utils = 'import \'../utils/currency_utils.dart\';' in content or 'import \'utils/currency_utils.dart\';' in content
    
    # 1. replace: '${double.tryParse(p['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} €'
    content = re.sub(r"'\$\{double\.tryParse\(([^)]+)\)\?\.toStringAsFixed\(2\) \?\? '0\.00'\} €'", r"CurrencyUtils.formatEuro(CurrencyUtils.parseCurrency(\1))", content)
    content = re.sub(r"'\$\{double\.tryParse\(([^)]+)\)\?\.toStringAsFixed\(2\) \?\? '0\.00'\}'", r"CurrencyUtils.formatUI(CurrencyUtils.parseCurrency(\1))", content)
    
    # 2. '€ ${amount.toStringAsFixed(2)}' -> CurrencyUtils.formatEuro(amount)
    content = re.sub(r"'€ \$\{([^}]+)\.toStringAsFixed\(\d+\)\}'", r"CurrencyUtils.formatEuro(\1)", content)
    content = re.sub(r"'- € \$\{([^}]+)\.toStringAsFixed\(\d+\)\}'", r"'- ' + CurrencyUtils.formatEuro(\1)", content)
    content = re.sub(r"'€\$\{([^}]+)\.toStringAsFixed\(\d+\)\}'", r"CurrencyUtils.formatEuro(\1)", content)
    content = re.sub(r"'€\$\{([^}]+)\.toStringAsFixed\(\d+\)\}k'", r"CurrencyUtils.formatEuro(\1) + 'k'", content)
    
    # 3. '${pct.toStringAsFixed(0)}%' -> '${CurrencyUtils.formatUI(pct, decimals: 0)}%'
    content = re.sub(r"'\$\{([^}]+)\.toStringAsFixed\((\d+)\)\}?'", r"CurrencyUtils.formatUI(\1, decimals: \2)", content)
    # The previous regex matched percentage strings, wait, if it matches '${margin.toStringAsFixed(1)}%' -> CurrencyUtils.formatUI(margin, decimals: 1) but we lose the %?
    # No, the regex didn't include the %. 
    # Let's fix regex 3
    content = re.sub(r"\$\{([^}]+)\.toStringAsFixed\((\d+)\)\}", r"${CurrencyUtils.formatUI(\1, decimals: \2)}", content)
    
    # 4. update_dialog: '${(progress * 100).toStringAsFixed(0)}%'
    # The previous rule #3 will cover this!
    
    # 5. deadlines_screen: 'Importo: €${amount.toStringAsFixed(2)}'
    # Rule #3 makes it: 'Importo: €${CurrencyUtils.formatUI(amount, decimals: 2)}'
    # That is perfectly fine!
    
    if content != original:
        if not has_currency_utils and 'CurrencyUtils' in content:
            # Figure out import path
            depth = filepath.replace(lib_path, '').count(os.sep) - 1
            if depth < 0: depth = 0
            prefix = '../' * depth
            if depth == 0:
                import_stmt = "import 'utils/currency_utils.dart';\n"
            else:
                import_stmt = f"import '{prefix}utils/currency_utils.dart';\n"
            
            # Put after last import
            last_import = content.rfind("import '")
            if last_import != -1:
                end_of_line = content.find("\n", last_import)
                content = content[:end_of_line+1] + import_stmt + content[end_of_line+1:]
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(lib_path):
    for file in files:
        if file.endswith('.dart'):
            replace_in_file(os.path.join(root, file))
