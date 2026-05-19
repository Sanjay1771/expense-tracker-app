import re

with open('analyze_output2.txt', 'r', encoding='utf-16') as f:
    lines = f.readlines()

for line in lines:
    if 'const_eval_method_invocation' in line:
        match = re.search(r'error - (lib[^\s:]+):(\d+):', line)
        if match:
            filepath = match.group(1)
            line_num = int(match.group(2)) - 1
            
            with open(filepath, 'r', encoding='utf-8') as src:
                content_lines = src.readlines()
            
            # Replace occurrences of 'const ' with '' on that line
            # Wait, replacing 'const ' might replace other valid consts on the same line,
            # but usually it's fine for Flutter code to remove const locally to fix the error.
            content_lines[line_num] = content_lines[line_num].replace('const ', '')
            
            with open(filepath, 'w', encoding='utf-8') as src:
                src.writelines(content_lines)
            print(f"Fixed const in {filepath}:{line_num+1}")
