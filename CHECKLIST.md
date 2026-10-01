# ✅ Checklist Peningkatan — UmadoApp
---

##  Krusial

- [X] **Skor Keaktifan dari tugas** — masukkan komponen "tugas tepat waktu" ke Statistik (update RPC stats_summary / stats_series + kartu Keaktifan)
- [X] **Edit tugas** — modul Tugas baru bisa create & delete, belum ada edit
- [X] **Validasi waktu saat absen** — RPC check-in cek apakah now() berada di rentang start_time–end_time kegiatan
- [X] **Kredensial Supabase tidak hardcoded** — pindah supabase_config.dart ke --dart-define/env, jangan di-commit
- [ ] **Lupa / reset password**
- [] **Konfirmasi email + deep link** untuk produksi (sempat dimatikan saat dev)
- [X] **Storage bucket + policy** untuk foto profil & lampiran tugas (attachment_url sudah ada di DB)
- [X] **Pesan error lebih ramah** — parse PostgrestException / AuthException jadi pesan spesifik

##  Penting tapi bisa nanti

- [X] **Foto profil** (upload avatar) — sekarang hanya inisial
- [X] **Notifikasi / pengingat** — deadline tugas & kegiatan akan mulai (local notif / FCM)
- [X] **Realtime daftar kehadiran** — auto-update saat petugas scan (Supabase Realtime)
- [X] **Bottom navigation bar** tetap — navigasi lebih cepat daripada grid menu
- [X] **Filter kegiatan** (hari ini / mendatang / lampau) di daftar Jadwal
- [X] **Riwayat kehadiran pribadi** — anggota lihat rekap check-in miliknya
- [X] **Peta lokasi kegiatan** — lihat titik & radius; pilih lokasi yang sudah ada + atur radius saat buat kegiatan
- [X] **Lampiran tugas** (file / link), bukan hanya catatan teks
- [X] **Overdue tugas otomatis** — update status via job/trigger, bukan hanya dihitung di HP

##  Kalo Niat

- [ ] **Dark mode**
- [ ] **Export rekap** (CSV / PDF) untuk admin
- [ ] **Dashboard admin** ringkasan lintas anggota
- [ ] **QR dua arah** (anggota juga bisa scan QR kegiatan)
- [ ] **Multi-organisasi** (tenant) bila dipakai banyak instansi
- [ ] **Audit log** aktivitas

## 🔧 Kualitas Kode / Teknis

- [ ] **Model pakai freezed + json_serializable** (sekarang fromMap manual)
- [ ] **Widget reusable** untuk loading / empty / error (kurangi duplikasi)
- [ ] **Konstanta route terpusat** (hindari string '/attendance' bertebaran)
- [ ] **Pisahkan warna status dari model** — mapping warna di lapisan UI, bukan di model
- [ ] **Index database** pada FK & start_time / deadline
- [ ] **Unit test** repository + widget test
- [ ] **Logging & crash reporting** (Sentry / Firebase Crashlytics)

## 🚀 Sebelum Rilis (Deployment)

- [X] **Nama, ikon, & splash native** (flutter_launcher_icons, flutter_native_splash)
- [X] **Samakan brand** — teks splash masih "Hadirin", ganti jadi "Umado"
- [ ] **Signing rilis** Android (keystore) & iOS
- [ ] **Project Supabase produksi** terpisah + review RLS + backup rutin
- [ ] **Aktifkan kembali konfirmasi email** yang dimatikan saat dev

---

### ⭐ Rekomendasi 3 langkah pertama
1. [X] Skor Keaktifan dari tugas
2. [X] Validasi waktu saat absen
3. [X] Edit tugas
