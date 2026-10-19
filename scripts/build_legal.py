"""Build public privacy HTML from the same text displayed in the Flutter app."""
import html
import re
from pathlib import Path
root = Path(__file__).resolve().parent.parent
source = (root / 'lib/screens/privacy.dart').read_text(encoding='utf-8')
sections = re.findall(r"'([^']+)':\s*'([^']*)'", source.split('class PrivacyPage')[0])
if len(sections) < 8:
    raise SystemExit('Privacy text could not be parsed; review before publishing.')
content = ''.join(f'<section><h2>{html.escape(title)}</h2><p>{html.escape(body)}</p></section>' for title, body in sections)
template = '''<!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Kebijakan privasi — LangkahKerja</title><link rel="stylesheet" href="legal.css"></head><body><main><a class="brand" href="privacy.html">▟ LangkahKerja</a><h1>Privasi, dalam kendalimu.</h1><p>Benelovent · 17 Oktober 2026</p>__CONTENT__<footer><a href="delete-account.html">Hapus akun dan data</a> · <a href="mailto:sastraxez@gmail.com">Hubungi Benelovent</a></footer></main></body></html>'''
target = root / 'docs/legal/privacy.html'
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(template.replace('__CONTENT__', content), encoding='utf-8')
print(f'Generated {len(sections)} privacy sections; host docs/legal/ on HTTPS after configuration.')
