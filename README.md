# P3NR V3 — Kecamatan Tanjungsari

Aplikasi P3NR / Buku Register Nikah Multi Desa untuk Kecamatan Tanjungsari, Kabupaten Sumedang, Jawa Barat.

## Isi paket

- `index.html` — aplikasi web P3NR, termasuk halaman login dan logo Kementerian Agama yang sudah ditanam di HTML.
- `assets/Kementerian_Agama_new_logo.png` — file logo sumber untuk repository/aset.
- `SETUP-SUPABASE-P3NR-TANJUNGSARI.sql` — SQL siap dijalankan di Supabase SQL Editor.
- `supabase/migrations/20260906000000_p3nr_v3_tanjungsari.sql` — salinan SQL dalam struktur migration.
- `.env.example` — contoh variabel konfigurasi, tanpa secret.
- `.gitignore` — mencegah file environment lokal ikut masuk Git.

## 1. Setup Supabase

1. Buat project baru di Supabase.
2. Buka **SQL Editor**.
3. Jalankan seluruh isi `SETUP-SUPABASE-P3NR-TANJUNGSARI.sql`.
4. Pastikan tabel `villages`, `profiles`, `village_settings`, dan `registers` sudah terbentuk.
5. Pastikan RLS aktif pada tabel-tabel tersebut.
6. Buka **Authentication → Users** dan buat akun pengguna.
7. Salin UUID setiap user.
8. Masukkan UUID tersebut ke tabel `profiles` dengan role:
   - `admin_kecamatan` untuk Admin Kecamatan; `village_id` kosong.
   - `petugas_desa` untuk Petugas Desa; `village_id` harus menunjuk desa tugasnya.

## 2. Daftar 12 desa

SQL sudah menyiapkan:

1. Gudang
2. Tanjungsari
3. Jatisari
4. Margaluyu
5. Kutamandiri
6. Margajaya
7. Raharja
8. Cijambu
9. Pasigaran
10. Gunungmanik
11. Kadakajaya
12. Cinanjung

## 3. Hubungkan HTML ke Supabase

Buka `index.html`, cari `MULTI_DESA_CONFIG` dan isi:

- `SUPABASE_URL` dengan URL project Supabase.
- `SUPABASE_ANON_KEY` / publishable key dengan key publik project.

Jangan memasukkan `service_role` key atau secret key ke HTML/GitHub.

## 4. GitHub

Buat repository, misalnya `p3nr-tanjungsari`, lalu unggah seluruh isi folder ini. Struktur yang disarankan:

```
p3nr-tanjungsari/
├── index.html
├── assets/
│   └── Kementerian_Agama_new_logo.png
├── SETUP-SUPABASE-P3NR-TANJUNGSARI.sql
├── supabase/
│   └── migrations/
│       └── 20260906000000_p3nr_v3_tanjungsari.sql
├── .env.example
├── .gitignore
└── README.md
```

## 5. Netlify

Hubungkan repository GitHub ke Netlify. Untuk HTML statis ini, publish directory dapat diarahkan ke root repository dan file utama adalah `index.html`.

## Catatan keamanan

Hak akses bukan hanya disembunyikan di tampilan HTML. Database Supabase menggunakan Row Level Security (RLS), sehingga Petugas Desa dibatasi pada `village_id` yang ditetapkan di `profiles`.

Jangan menaruh password pengguna, service-role key, atau secret Supabase di GitHub.
