from pathlib import Path
text = Path('src/components/AddExpenseDialog.js').read_text(encoding='utf-8')
idx = text.index('Novo')
print(text[idx-10:idx+40])
