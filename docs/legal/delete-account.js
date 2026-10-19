/* OTP -> bearer token in memory -> authenticated deletion. No session storage. */
(() => {
  const get = id => document.getElementById(id);
  const say = text => { get('message').textContent = text; };
  const config = window.LANGKAHKERJA_CONFIG ?? {};
  let origin;
  try { origin = new URL(config.supabaseUrl); } catch { /* handled below */ }
  if (!origin || origin.protocol !== 'https:' || !config.publishableKey || String(config.publishableKey).startsWith('sb_secret_')) {
    get('email-form').hidden = true;
    say('Penghapusan melalui web belum diaktifkan. Gunakan penghapusan di aplikasi atau kirim permintaan dari email akunmu ke sastraxez@gmail.com.');
    return;
  }
  const base = origin.origin;
  let email = '', accessToken = '';
  async function request(path, body, token) {
    const response = await fetch(base + path, {method:'POST',credentials:'omit',headers:{apikey:config.publishableKey,'Content-Type':'application/json',...(token ? {Authorization:'Bearer '+token} : {})},body:JSON.stringify(body),signal:AbortSignal.timeout(30000)});
    if (!response.ok) throw new Error('Request not completed');
    return response.json();
  }
  say('Verifikasi email untuk meminta penghapusan akun dan data.');
  get('email-form').addEventListener('submit', async event => {
    event.preventDefault(); get('send').disabled = true;
    email = get('email').value.trim();
    try {
      await request('/auth/v1/otp',{email,create_user:false});
      get('email-form').hidden = true; get('verify-form').hidden = false;
      say('Jika email terdaftar, kode akan dikirim. Periksa folder spam.'); get('code').focus();
    } catch { say('Kode belum dapat dikirim. Periksa email, tunggu sebentar, lalu coba lagi.'); }
    finally { get('send').disabled = false; }
  });
  get('verify-form').addEventListener('submit', async event => {
    event.preventDefault(); get('verify').disabled = true;
    try {
      const result = await request('/auth/v1/verify',{email,token:get('code').value.trim(),type:'email'});
      if (!result.access_token) throw new Error('No token');
      accessToken = result.access_token;
      get('code').value = ''; get('verify-form').hidden = true; get('delete-form').hidden = false;
      say('Email terverifikasi. Penghapusan permanen memerlukan konfirmasi di bawah ini.'); get('confirmation').focus();
    } catch { say('Kode tidak valid, kedaluwarsa, atau koneksi terganggu. Coba lagi; muat ulang halaman untuk meminta kode baru.'); }
    finally { get('verify').disabled = false; }
  });
  get('delete-form').addEventListener('submit', async event => {
    event.preventDefault();
    if (get('confirmation').value.trim() !== 'HAPUS') { say('Ketik HAPUS dengan tepat untuk melanjutkan.'); return; }
    get('delete').disabled = true;
    try {
      const result = await request('/functions/v1/delete-account',{},accessToken);
      if (result.deleted !== true) throw new Error('Deletion not confirmed');
      accessToken = ''; get('delete-form').hidden = true; say('Akun dan data terkait berhasil dihapus dari sistem aktif. Bersihkan data lokal pada setiap perangkat jika diperlukan.');
    } catch { say('Penghapusan belum dikonfirmasi server. Muat ulang halaman dan verifikasi email dengan kode baru sebelum mencoba lagi.'); }
    finally { get('delete').disabled = false; }
  });
})();
