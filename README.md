# ⚽ LigaPass

> Aplikasi pemesanan tiket pertandingan sepak bola dan berita terbaru sepak bola berbasis mobile.

---

## 👷 Anggota Kelompok
- [Jaysen Lestari](https://github.com/Jaysenlestari) - 2406395335  
- [Nadia Aisyah Fazila](https://github.com/applepiesss) - 2406495584  
- [Muhammad Aldo Fahrezy](https://github.com/aldofahrezy) - 2406423055  
- [Refki Septian](https://github.com/RefkiSeptian) - 2406397196  
- [Mei Ching](https://github.com/https://github.com/Mei2462) - 2406361662  

---

## 📝 Deskripsi Singkat
LigaPass adalah aplikasi berbasis mobile yang memudahkan penggemar sepak bola untuk memesan tiket pertandingan secara praktis sekaligus mengikuti berita terkini seputar dunia bola. Dengan antarmuka yang sederhana dan informatif, pengguna bisa menemukan jadwal pertandingan, memilih kategori tempat duduk sesuai kebutuhan, serta melakukan pembayaran dengan aman dan cepat.

Selain fitur pemesanan, LigaPass juga menghadirkan berita bola terbaru, analisis pertandingan, dan update transfer pemain yang dikurasi agar tetap relevan dengan minat pengguna. Kombinasi layanan pemesanan tiket dan portal berita ini membuat LigaPass menjadi solusi all-in-one bagi para pecinta sepak bola yang ingin mendapatkan pengalaman menonton lebih seru dan informatif.

---

## 🧩 Modul yang Diimplementasikan
1. **Login & Authentication**      
*Dikerjakan oleh Jaysen Lestari*   
Registrasi, login, logout, dan manage cookie untuk mendapatkan role yang sesuai.
2. **Profile Management**  
*Dikerjakan oleh Nadia Aisyah Fazila*  
   Modul Profile menyediakan halaman profil untuk tiga peran: **User**, **Admin**, dan **Jurnalis**. Pengguna dapat melihat serta mengedit data dasar seperti foto, nama lengkap, username, email, nomor telepon, dan tanggal lahir. Admin dapat meninjau profil pengguna beserta riwayat pembelian tiket dan riwayat ulasan, serta mengelola status akun seperti aktif, suspended, atau banned(opsional). **Admin** dan **Jurnalis** bersifat **hardcoded**. Journalist memiliki ringkasan kinerja konten, seperti total tayang dan jumlah berita yang telah dipublikasikan.
3. **News**  
*Dikerjakan oleh Mei Ching*  
   Modul ini menyediakan halaman utama daftar berita yang dapat difilter dan search berdasarkan keyword. Akses berbasis peran: User melihat semua berita, sedangkan Journalist mendapat tombol Create News untuk membuat berita baru. Pada detail berita, Journalist juga melihat Edit News untuk memperbarui atau menghapus; setelah disunting, label tanggal berubah menjadi “tanggal disunting”. Selain itu, User dan Journalist dapat berinteraksi dengan menuliskan comment pada halaman news detail.
4. **Matches**  
*Dikerjakan oleh Muhammad Aldo Fahrezy*  
   Aplikasi ini mencakup pipeline inisialisasi data (data seeding) dari dataset Kaggle dengan preprocessing/cleaning untuk menstandarkan nama tim, format tanggal–waktu, dan menangani missing/inconsistency sebelum masuk ke model Team dan Match. Admin punya CRUD penuh untuk data master: mengelola klub (tambah, lihat, ubah nama/logo, hapus) dan jadwal pertandingan (buat, lihat, ubah waktu–stadion–harga tiket, hapus). Di sisi pengguna, tersedia halaman kalender yang otomatis mengelompokkan pertandingan menjadi Upcoming, Ongoing, dan Past berdasarkan waktu saat ini, serta halaman detail pertandingan yang menampilkan info kedua tim, kickoff, stadion, harga tiket, dan ketersediaannya
4. **Product Management**  
*Dikerjakan oleh Jaysen Lestari*  
   Aplikasi ini memungkinkan user memilih pertandingan dari halaman utama, lalu memilih kategori tiket (VVIP/VIP/Reguler), memvalidasi ketersediaan kursi, menentukan jumlah (opsional bundle/promo), dan membuat pesanan. Untuk pembayaran, pengguna dapat membayar dengan berbagai pilihan seperti qris, virtual account ataupun visa/mastercard. Setelah pembayaran diverifikasi, maka tiket dari user dapat dicek di bagian profile, tiket juga dapat di download dalam format png.
5. **Review & Comment**  
*Dikerjakan oleh Refki Septian*  
   Pada bagian modul ini, admin dapat melihat fitur analitik yang menampilkan ringkasan tiket terjual pada hari itu, minggu ini, dan bulan ini (dipilih berdasarkan filter) serta pendapatan pada hari itu, minggu itu, dan bulan itu (dipilih berdasarkan filter)selain itu, admin juga dapat memantau melihat review dari penonton dan membalas review untuk setiap pertandingan. Untuk User, tersedia statistik kehadiran, grafik pengeluaran harian, mingguan, dan bulanan (dipisahkan berdasar review), pengguna juga dapat memberikan rating pertandingan dan menuliskan komentar pengalaman menonton.
   
---

## 📊 Dataset
- **Match** (Indonesia) : https://rapidapi.com/Creativesdev/api/free-api-live-football-data

---

## 👤Role
- **User** : User dapat melakukan registrasi, login, serta mengelola profil pribadi mereka. Mereka bisa membeli tiket pertandingan dengan memilih kategori kursi (VVIP, VIP, Reguler), melakukan pembayaran, dan mendapatkan tiket digital. User juga memiliki riwayat pembelian, statistik kehadiran, grafik pengeluaran, serta dapat memberikan review dan komentar pada pertandingan maupun berita.
- **Admin** : Admin memiliki kendali penuh terhadap sistem, mulai dari manajemen data klub dan pertandingan (CRUD), verifikasi pembayaran, hingga monitoring penjualan tiket melalui dashboard analitik. Admin juga dapat meninjau profil pengguna, mengelola status akun, serta memantau ulasan penonton lengkap dengan rating, komentar, dan visualisasi tren. Dengan akses ini, Admin berperan penting dalam menjaga kelancaran operasional aplikasi.
- **Journalist** : journalist berfokus pada pengelolaan konten berita. Mereka memiliki akses untuk membuat, mengedit, dan menghapus berita, serta melihat ringkasan kinerja konten berupa total tayang dan jumlah artikel yang dipublikasikan. Pada halaman berita, Journalist mendapat tombol khusus untuk membuat berita baru dan mengelola konten yang sudah ada. Dengan demikian, Journalist menjadi sumber utama informasi terbaru bagi pengguna aplikasi.

--- 

## 📌 Alur Pengintegrasian dengan web service
Pada proses pengintegrasian antara Django dengan Flutter, kami akan melakukan beberapa langkah berikut:
1. Menambahkan package http pada proyek Flutter

    Package ini digunakan agar aplikasi mobile dapat mengirim request (GET/POST) ke web service Django.
2. Memanfaatkan sistem autentikasi Django yang sudah dibuat pada Proyek Tengah Semester
     
    Fitur login, logout, dan registrasi digunakan kembali sehingga pengguna yang login melalui Flutter tetap mendapatkan hak akses sesuai rolenya (misalnya user biasa atau admin atau journalist).
3. Menggunakan package pbp_django_auth untuk mengelola session dan cookie

    Package ini membantu Flutter mempertahankan sesi login Django, sehingga setiap request yang dikirim ke server akan membawa cookie autentikasi yang valid.
4. Membuat model Dart berdasarkan data JSON dari Django

    Setiap fitur (matches, bookings, news, profiles, reviews) dihubungkan melalui endpoint JSON yang sudah disediakan Django. Untuk mempermudah proses konversi JSON → Dart, kami akan menggunakan quicktype (https://app.quicktype.io/) untuk membuat class model secara otomatis.
5. Menghubungkan UI Flutter dengan API Django melalui service per fitur

    Flutter memanggil endpoint Django melalui kelas service (misalnya MatchService, BookingService, dll), kemudian hasilnya diolah menjadi objek Dart dan ditampilkan pada UI seperti list view atau detail page.

---

## 🔗 URL
**Deployment** (web): https://jaysen-lestari-ligapass.pbp.cs.ui.ac.id/   
**Figma** : https://www.figma.com/design/IZxjKlwpj4As5MbLBrLpZL/LigaPass-Mobile-Apps?node-id=0-1&t=UlYPYjwcnodUTghb-1