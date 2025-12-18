# ⚽ LigaPass

> Aplikasi pemesanan tiket pertandingan sepak bola dan berita sepak bola terkini berbasis mobile.

---

## 👷 Anggota Kelompok
- [Jaysen Lestari](https://github.com/Jaysenlestari) - 2406395335
- [Nadia Aisyah Fazila](https://github.com/applepiesss) - 2406495584
- [Muhammad Aldo Fahrezy](https://github.com/aldofahrezy) - 2406423055
- [Refki Septian](https://github.com/RefkiSeptian) - 2406397196
- [Mei Ching](https://github.com/Mei2462) - 2406361662

---

## 📝 Deskripsi Singkat
LigaPass adalah aplikasi berbasis mobile yang memudahkan penggemar sepak bola untuk memesan tiket pertandingan secara praktis sekaligus mengikuti berita terkini seputar dunia sepak bola. Dengan antarmuka yang sederhana dan informatif, pengguna dapat melihat jadwal pertandingan, memilih kategori tempat duduk sesuai kebutuhan, serta melakukan pembayaran secara aman dan cepat.

Selain fitur pemesanan tiket, LigaPass juga menghadirkan berita sepak bola terbaru, analisis pertandingan, serta pembaruan transfer pemain yang dikurasi agar tetap relevan dengan minat pengguna. Kombinasi layanan pemesanan tiket dan portal berita ini menjadikan LigaPass sebagai solusi *all-in-one* bagi para pecinta sepak bola untuk mendapatkan pengalaman menonton yang lebih seru dan informatif.

---

## 🧩 Modul yang Diimplementasikan
1. **Login & Authentication** — *Dikerjakan oleh Jaysen Lestari*  
   Modul ini mencakup registrasi, login, logout, serta pengelolaan cookie untuk memastikan pengguna memperoleh hak akses sesuai dengan perannya.

2. **Profile Management** — *Dikerjakan oleh Nadia Aisyah Fazila*  
   Modul Profile menyediakan halaman profil untuk tiga peran, yaitu **User**, **Admin**, dan **Journalist**. Pengguna dapat melihat dan mengedit data dasar seperti foto profil, nama lengkap, username, email, nomor telepon, dan tanggal lahir.  
   Admin dapat meninjau profil pengguna beserta riwayat pembelian tiket dan riwayat ulasan, serta mengelola status akun seperti aktif, *suspended*, atau *banned* (opsional).  
   **Admin** dan **Journalist** bersifat **hardcoded**, yaitu masing-masing hanya tersedia satu akun tetap yang telah ditentukan di sistem dan tidak dapat diregistrasi oleh pengguna umum. Journalist juga memiliki ringkasan kinerja konten, seperti total tayang dan jumlah berita yang telah dipublikasikan.

3. **News** — *Dikerjakan oleh Mei Ching*  
   Modul ini menyediakan halaman utama daftar berita yang dapat difilter dan dicari berdasarkan kata kunci. Akses bersifat berbasis peran: **User** dapat melihat seluruh berita, sedangkan **Journalist** memiliki tombol *Create News* untuk membuat berita baru.  
   Pada halaman detail berita, Journalist juga memiliki akses *Edit News* untuk memperbarui atau menghapus berita. Jika berita disunting, label tanggal akan berubah menjadi “tanggal disunting”. Selain itu, **User** dan **Journalist** dapat berinteraksi dengan menuliskan komentar pada halaman detail berita.

4. **Matches** — *Dikerjakan oleh Muhammad Aldo Fahrezy*  
   Modul ini mencakup proses inisialisasi data (*data seeding*) dari dataset eksternal dengan tahap *preprocessing* dan *cleaning*, seperti standarisasi nama tim, format tanggal dan waktu, serta penanganan data yang tidak konsisten atau hilang sebelum dimasukkan ke dalam model **Team** dan **Match**.  
   Admin memiliki akses penuh (*CRUD*) untuk mengelola data klub dan jadwal pertandingan. Sementara itu, pengguna dapat melihat kalender pertandingan yang secara otomatis dikelompokkan menjadi **Upcoming**, **Ongoing**, dan **Past**, serta mengakses halaman detail pertandingan.

5. **Product Management** — *Dikerjakan oleh Jaysen Lestari*  
   Modul ini memungkinkan pengguna memilih pertandingan, menentukan kategori tiket (VVIP, VIP, Reguler), memvalidasi ketersediaan kursi, dan menentukan jumlah tiket.  
   Pembayaran dapat dilakukan melalui beberapa metode, seperti QRIS, *virtual account*, maupun kartu Visa/Mastercard. Setelah pembayaran diverifikasi, tiket dapat diakses melalui halaman profil dan diunduh dalam format PNG.

6. **Review & Comment** — *Dikerjakan oleh Refki Septian*  
   Modul ini menyediakan fitur analitik bagi admin, berupa ringkasan tiket terjual, pendapatan, tren penjualan, visualisasi okupansi kursi, serta agregasi ulasan penonton berupa **rating rata-rata dan komentar**.  
   Bagi pengguna, modul ini menampilkan riwayat pembelian tiket, statistik kehadiran, grafik pengeluaran bulanan maupun tahunan, serta memungkinkan pengguna memberikan rating dan komentar atas pengalaman menonton pertandingan.  
   Admin juga memiliki dashboard pesanan yang menampilkan metrik seperti total pesanan, jumlah tiket terjual, total pendapatan, dan sisa tiket, serta halaman detail untuk setiap pesanan.

---

## 📊 Dataset
Dataset pertandingan sepak bola Indonesia diperoleh melalui API berikut:  
https://rapidapi.com/Creativesdev/api/free-api-live-football-data

---

## 👤 Role
- **User**  
  User dapat melakukan registrasi, login, dan mengelola profil pribadi. User dapat membeli tiket pertandingan, melakukan pembayaran, mengakses tiket digital, melihat riwayat pembelian, serta memberikan review dan komentar.

- **Admin**  
  Admin memiliki kendali penuh terhadap sistem, termasuk pengelolaan data klub dan pertandingan, verifikasi pembayaran, serta pemantauan penjualan tiket dan ulasan pengguna melalui dashboard analitik.

- **Journalist**  
  Journalist bertugas mengelola konten berita, mulai dari membuat, mengedit, hingga menghapus berita, serta melihat ringkasan performa konten yang telah dipublikasikan.

---

## 📌 Alur Pengintegrasian dengan Web Service
1. **Menambahkan package `http` pada proyek Flutter**  
   Package ini digunakan agar aplikasi mobile dapat mengirim permintaan (*request*) GET dan POST ke web service Django.

2. **Memanfaatkan sistem autentikasi Django**  
   Fitur login, logout, dan registrasi yang telah dibuat sebelumnya digunakan kembali sehingga pengguna yang login melalui Flutter tetap memperoleh hak akses sesuai perannya (misalnya user biasa, admin, atau journalist).

3. **Menggunakan package `pbp_django_auth` untuk mengelola sesi**  
   Package ini membantu Flutter mempertahankan sesi login Django sehingga setiap request yang dikirim ke server membawa cookie autentikasi yang valid.

4. **Membuat model Dart dari data JSON Django**  
   Setiap fitur (matches, bookings, news, profiles, dan reviews) dihubungkan melalui endpoint JSON. Konversi JSON ke Dart dilakukan dengan bantuan *quicktype*.

5. **Menghubungkan UI Flutter dengan API Django melalui service**  
   Flutter memanggil endpoint Django melalui kelas service per fitur, seperti **MatchService** dan **BookingService**, kemudian hasilnya ditampilkan pada antarmuka pengguna.

---

## 🔗 URL
- **Deployment (Web)**  
  https://jaysen-lestari-ligapass.pbp.cs.ui.ac.id/

- **Figma Design**  
  https://www.figma.com/design/IZxjKlwpj4As5MbLBrLpZL/LigaPass-Mobile-Apps

- **User Flow**  
  https://www.figma.com/proto/IZxjKlwpj4As5MbLBrLpZL/LigaPass-Mobile-Apps

- **Admin Flow**  
  https://www.figma.com/proto/IZxjKlwpj4As5MbLBrLpZL/LigaPass-Mobile-Apps

- **Journalist Flow**  
  https://www.figma.com/proto/IZxjKlwpj4As5MbLBrLpZL/LigaPass-Mobile-Apps

---

## 📥 Download
> *(Akan diperbarui setelah proses deployment ulang selesai)*
