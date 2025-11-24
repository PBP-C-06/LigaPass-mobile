# ⚽ LigaPass Mobile
LigaPass adalah aplikasi mobile untuk memesan tiket pertandingan sepak bola, mengikuti berita terkini, dan kini terhubung ke backend Django untuk data pertandingan.

## 👥 Anggota Kelompok
- [Jaysen Lestari](https://github.com/Jaysenlestari) - 2406395335  
- [Nadia Aisyah Fazila](https://github.com/applepiesss) - 2406495584  
- [Muhammad Aldo Fahrezy](https://github.com/aldofahrezy) - 2406423055  
- [Refki Septian](https://github.com/RefkiSeptian) - 2406397196  
- [Mei Ching](https://github.com/https://github.com/Mei2462) - 2406361662  

## 📝 Deskripsi Singkat
LigaPass memudahkan penggemar bola menemukan jadwal pertandingan, membeli tiket (VVIP/VIP/Reguler), dan mengikuti berita dengan pengalaman all-in-one. Admin/jurnalis dapat mengelola konten dan data pertandingan.

## 🧩 Modul
1. **Login & Authentication** — registrasi, login, logout, Google Sign-In (pbp_django_auth).
2. **Profile Management** — profil untuk User/Admin/Jurnalis; admin dapat meninjau riwayat pembelian/ulasan.
3. **News** — daftar & detail berita, komentar, create/edit/delete untuk jurnalis.
4. **Matches** — kalender pertandingan dari Django (`/matches/api/calendar/`), status Upcoming/Ongoing/Finished, detail match; admin CRUD tim/venue/match.
5. **Product (Tickets)** — pilih kategori tiket, validasi ketersediaan, pembayaran, tiket digital.
6. **Review & Comment** — rating/komentar pertandingan, dashboard admin untuk analitik penjualan & review.

## 🔗 Sumber Data
- Match (ID): https://rapidapi.com/Creativesdev/api/free-api-live-football-data

## ⚙️ Setup & Run
1) Install dependensi: `flutter pub get`  
2) Jalankan Django di port 8000 (default): `python manage.py runserver 8000`  
3) Jalankan Flutter:
```bash
# Web / desktop / iOS simulator (default ke http://localhost:8000)
flutter run -d chrome --web-port 5000

# Android emulator (default ke http://10.0.2.2:8000)
flutter run

# Override base URL (mis. device fisik / LAN)
flutter run --dart-define API_BASE_URL=http://<your-ip>:8000
```

## 🛰️ Integrasi Django ↔ Flutter (Matches)
- Data layer: model/filter/pagination sesuai JSON `/matches/api/calendar/`.
- Client: `MatchesApiClient` + `MatchesRepository` + `MatchesNotifier` (Provider).
- UI: list dengan status badge, logo tim, venue, pagination; detail page per match.
- Catatan backend: API kalender belum expose `api_id`/ticket prices/detail JSON. Tambahkan jika perlu live score (`/matches/api/live-score/<api_id>/`) atau harga tiket via endpoint JSON.

## 🔧 Dev Notes
- Theme: `AppTheme.light` (Google Fonts Poppins).
- Env: `lib/config/env.dart` untuk konfigurasi dasar; API base URL bisa di-override via `--dart-define API_BASE_URL=...`.
- Asset: `assets/google.png` untuk tombol Google Sign-In.
