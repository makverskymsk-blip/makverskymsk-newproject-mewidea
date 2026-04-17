"""
Patches members_screen.dart:
1. Adds 2 imports (sport_match, matches_provider)
2. Replaces the old RefreshIndicator...confirmSettle block with new per-event code
"""
main_file = r'e:\src\projects\new_idea_works\lib\screens\community\members_screen.dart'
new_section_file = r'C:\Users\Makversky\.gemini\antigravity\brain\df81c849-2ba3-4a3c-a867-8f22e5a1c5a9\scratch\new_debtors_section.dart'

with open(main_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

with open(new_section_file, 'r', encoding='utf-8') as f:
    new_section_lines = f.readlines()

print(f'Original lines: {len(lines)}')

# Step 1: Add imports
assert 'enums.dart' in lines[3], f'Anchor fail at idx 3: {lines[3]}'
assert 'community_provider.dart' in lines[7], f'Anchor fail at idx 7: {lines[7]}'

lines.insert(8, "import '../../providers/matches_provider.dart';\r\n")
lines.insert(4, "import '../../models/sport_match.dart';\r\n")
print(f'After imports: {len(lines)}')

# Step 2: Find exact replacement boundaries (shifted +2 by imports)
start_idx = None
end_idx = None
for i, l in enumerate(lines):
    if start_idx is None and 'return RefreshIndicator(' in l and i > 300:
        start_idx = i
    if start_idx is not None and l.strip() == '}' and i > start_idx + 200:
        # This should be the closing } of _confirmSettle
        # Verify next non-empty line is _roleBadge or similar
        for j in range(i+1, min(i+5, len(lines))):
            if lines[j].strip():
                if '_roleBadge' in lines[j] or 'Widget' in lines[j]:
                    end_idx = i
                break
        if end_idx is not None:
            break

print(f'Replacing idx {start_idx}-{end_idx} (lines {start_idx+1}-{end_idx+1})')
print(f'  Start: {lines[start_idx].rstrip()}')
print(f'  End:   {lines[end_idx].rstrip()}')

before = lines[:start_idx]
after = lines[end_idx+1:]

result_lines = before + new_section_lines + after
result = ''.join(result_lines)

with open(main_file, 'w', encoding='utf-8', newline='') as f:
    f.write(result)

print(f'Final lines: {len(result_lines)}')
print('Done!')
