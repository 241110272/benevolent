"""Fail early for missing public runtime config/signing. Never prints secrets."""
import base64
import json
from pathlib import Path
from urllib.parse import urlparse

root = Path(__file__).resolve().parent.parent
errors = []
path = root / 'config/env.json'
config = {}
if path.exists():
    try:
        config = json.loads(path.read_text(encoding='utf-8-sig'))
    except (ValueError, OSError):
        errors.append('config/env.json tidak dapat dibaca.')
else:
    errors.append('Salin config/env.example.json ke config/env.json dan isi konfigurasi publik.')
for key in ('SUPABASE_URL', 'PRIVACY_URL', 'DELETION_URL'):
    parsed = urlparse(str(config.get(key, '')))
    if parsed.scheme != 'https' or not parsed.netloc or parsed.username:
        errors.append(f'{key} harus berupa URL HTTPS. Periksa akses publiknya secara terpisah.')
key = str(config.get('SUPABASE_PUBLISHABLE_KEY', ''))
if key.startswith('sb_secret_'):
    errors.append('Service/secret key tidak boleh dimasukkan ke aplikasi.')
elif key.startswith('sb_publishable_'):
    pass
elif key.count('.') == 2:
    try:
        body = json.loads(base64.urlsafe_b64decode(key.split('.')[1] + '==='))
        if body.get('role') != 'anon':
            errors.append('JWT aplikasi harus memakai role anon; jangan pakai service_role.')
    except ValueError:
        errors.append('Format publishable/anon key tidak valid.')
else:
    errors.append('SUPABASE_PUBLISHABLE_KEY belum diisi dengan public key yang valid.')
signing = root / 'android/key.properties'
if not signing.exists():
    errors.append('Upload signing key belum dikonfigurasi melalui android/key.properties.')
else:
    fields = {}
    for line in signing.read_text(encoding='utf-8-sig').splitlines():
        if '=' in line and not line.lstrip().startswith('#'):
            name, value = line.split('=', 1)
            fields[name.strip()] = value.strip()
    for field in ('storeFile', 'storePassword', 'keyAlias', 'keyPassword'):
        if not fields.get(field) or fields[field] == 'REPLACE_LOCALLY':
            errors.append(f'Konfigurasi signing {field} belum lengkap.')
    keystore = Path(fields.get('storeFile', ''))
    if not keystore.is_absolute():
        keystore = root / 'android' / keystore
    if not keystore.is_file():
        errors.append('Berkas upload keystore tidak ditemukan.')
if errors:
    print('BELUM SIAP MEMBUAT BUNDLE RILIS:')
    for error in errors:
        print(f'- {error}')
    raise SystemExit(1)
print('Konfigurasi lokal lengkap. Lanjutkan pengujian backend, perangkat, dan checklist Play Console di docs/RELEASE.md.')
