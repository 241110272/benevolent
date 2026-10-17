# Aset UI LangkahKerja

## Foto banner

`images/career-coworking.png` dibuat menggunakan tool imagegen bawaan untuk aplikasi ini. Disimpan sebagai aset lokal agar mode demo tidak membutuhkan layanan foto eksternal.

Prompt final:

> Use case: photorealistic-natural. Asset type: background photograph for a mobile Indonesian job search app banner. A warm candid editorial photograph of young adult Indonesian professionals working on laptops at a modern leafy coworking cafe, one friendly young woman with dark hair loosely tied up in the right third of the image, focused and smiling slightly at her laptop, another young male colleague with glasses softly blurred behind. Composition: landscape 3:2 photograph, waist-up, right-weighted subject, left half is soft background and darker interior with ample calm negative space for white headline overlay added separately by app code. Warm natural window light, wood desks, potted plants, creamy neutral tones, subtle purple shadows, tasteful realistic photographic texture. No lettering, no text, no logo, no watermark, no user interface, no phone frame. Output one photograph only.

## Font

Manrope dari repositori resmi Google Fonts. Lisensi ada di `fonts/OFL-Manrope.txt`. Font dibundel lokal; aplikasi tidak mengambil font dari jaringan saat dibuka.

## Identitas

Logo tangga digambar langsung melalui Flutter CustomPainter di `lib/widgets/brand.dart`. Warna utama plum `#281531`, lavender `#E8DFFA`, aksen lime `#EAF3B4`, dan latar `#FAF9F7`.
