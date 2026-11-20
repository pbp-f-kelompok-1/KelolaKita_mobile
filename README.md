# KelolaKita Mobile

## Deskripsi Aplikasi

**KelolaKita** adalah platform digital pengelolaan barang dan sampah yang membantu pengguna menentukan cara penanganan yang tepat berdasarkan jenis dan kondisi barang. Setiap barang yang disetorkan akan melalui pemeriksaan awal untuk menentukan kategori penanganan, yaitu **Recycle, Reduce, atau Reuse**.

Pada kategori **Recycle**, barang yang masih dapat didaur ulang dapat disetorkan melalui kantor KelolaKita atau titik setoran yang tersedia. Pengguna dapat memilih lokasi dan jadwal berdasarkan jarak serta kemudahan pengantaran. Barang yang telah dikumpulkan kemudian disalurkan kepada bank sampah untuk diproses lebih lanjut.

Pada kategori **Reuse**, barang yang masih memiliki nilai guna akan diarahkan untuk digunakan kembali oleh pihak yang membutuhkan. Barang berukuran kecil dapat disetorkan ke titik tertentu atau diantarkan langsung ke panti asuhan yang tersedia pada peta. Sementara itu, barang berukuran besar dapat dialihkan kepada komunitas untuk membantu proses penyaluran kepada pihak yang membutuhkan.

Sementara itu, kategori **Reduce** berfokus pada upaya mengurangi timbulan sampah yang tidak dapat didaur ulang sejak dari sumbernya. KelolaKita mendukung upaya tersebut melalui edukasi, kegiatan komunitas, dan promosi penggunaan produk yang dapat digunakan kembali, seperti tote bag, stainless steel bottle, reusable straw, dan produk ramah lingkungan lainnya.

KelolaKita hadir untuk membantu masyarakat mengelola barang dan sampah dengan lebih terarah. Melalui proses pemeriksaan dan penentuan kategori penanganan, setiap barang dapat diarahkan sesuai dengan kondisi dan potensi pemanfaatannya.

---

## Menjalankan Platform di Localhost

Ikuti langkah berikut untuk menjalankan aplikasi KelolaKita secara lokal:

1. Pastikan Flutter sudah terpasang, lalu buka terminal pada folder utama proyek.

2. Pastikan Google Chrome terdeteksi sebagai perangkat target:

	```cmd
	flutter devices
	```

    Daftar perangkat akan memuat baris `Chrome (web)`. Dukungan web sudah aktif secara bawaan pada Flutter versi stabil.

3. Jalankan aplikasi di Google Chrome dari root folder proyek:

	```bash
	flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
	```

### Menjalankan di Android Emulator atau Perangkat Fisik (Opsional)

Jika perangkat keras laptop kamu memadai (RAM 16 GB+), kamu juga dapat membuat Android Virtual Device (AVD) melalui Android Studio Device Manager, atau mengaktifkan fitur USB Debugging pada ponsel pintar Android milikmu, lalu menjalankan perintah:

```bash
flutter run
```

---

## Authentication dan Profile (Flutter)

Branch pengerjaan: `module/authentication-and-profile`. Buka tab **Profil** untuk
masuk, membuat akun, melihat/mengedit profil, memuat ulang data, dan keluar.
Tab Beranda, Ajukan, Jadwal, dan Edukasi tetap tersedia. Tampilan memakai tema
gelap hijau, aksen kuning, dan font Plus Jakarta Sans aplikasi.

### Kontrak backend yang benar-benar tersedia

Repo Django lokal `../KelolaKita` saat implementasi menyediakan endpoint
berbasis **session cookie + CSRF**, bukan API token/JWT. Karena itu adapter
`lib/features/account/account_api.dart` menggunakan kontrak berikut tanpa
menambah atau mengubah backend:

| Endpoint | Kontrak yang digunakan |
|---|---|
| `GET /accounts/login/` | Form HTML dan hidden `csrfmiddlewaretoken` |
| `POST /accounts/login/` | Form `username`, `password`, `remember_me=on`; sukses redirect |
| `GET /accounts/register/` | Form HTML dan token CSRF |
| `POST /accounts/register/` | `username`, `first_name`, `last_name`, `email`, `password1`, `password2`; sukses membuat sesi dan redirect |
| `GET /accounts/profile/` | HTML profil dan nilai input form; login diwajibkan |
| `POST /accounts/profile/` | Enam field profil, header `X-Requested-With: XMLHttpRequest`, token CSRF; JSON `success`, `errors`, `non_field_errors` |
| `POST /accounts/logout/` | Token CSRF; menghapus sesi server dan redirect |

Field profil yang dapat diedit: `first_name`, `last_name`, `email`,
`phone_number`, `address`, `avatar_url`. Username, peran, dan poin hanya dibaca.
Validasi Django tetap menjadi sumber kebenaran; pesannya ditampilkan di Flutter.
Adapter pembacaan HTML bergantung pada `data-profile-form`,
`data-profile-full-name`, field form, dan label ringkasan template Django saat
ini. Jika backend kelak menyediakan API JSON khusus akun, ganti adapter ini;
halaman Flutter dan controller tidak perlu bergantung pada template Django.

Cookie sesi native disimpan memakai `flutter_secure_storage`, dengan key
terpisah per origin backend. Kata sandi dan data profil tidak dipersistenkan.
Sesi divalidasi lagi ke Django saat aplikasi dibuka, sesi kedaluwarsa dibersihkan,
dan gangguan jaringan tetap menyimpan sesi agar bisa dicoba ulang. Login meminta
masa berlaku 14 hari sesuai `LoginForm` backend; registrasi mengikuti masa sesi
default Django. Di web, cookie HttpOnly ditangani browser; penyimpanan lokal hanya
menandai bahwa sesi perlu dipulihkan. Keluar berhasil setelah sesi server
diakhiri dan penyimpanan lokal dihapus.

### Menjalankan akun pada Android

Jalankan Django pada port 8000 menggunakan environment backend yang sudah ada.
Lalu dari **root repo mobile**:

```powershell
flutter pub get
adb reverse tcp:8000 tcp:8000
flutter run -d <id-perangkat-android> --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Alternatif untuk emulator Android tanpa `adb reverse`: gunakan
`--dart-define=API_BASE_URL=http://10.0.2.2:8000`. Untuk server deployment gunakan
URL HTTPS. Akses HTTP lokal hanya diizinkan oleh manifest debug yang sudah ada.

### Menjalankan akun pada Chrome tanpa mengubah Django

Server Django lokal saat ini belum menambahkan CORS untuk cookie lintas origin.
Gunakan proxy pengembangan yang disertakan agar Flutter Web dan akun Django
diakses dari origin yang sama, dengan pemeriksaan CSRF tetap aktif:

```powershell
# Terminal 1: jalankan Django di repo backend pada port 8000.
# Terminal 2, dari root repo mobile:
flutter build web --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:8080
python tool/serve_local_web.py --django http://127.0.0.1:8000
```

Buka [Flutter lokal](http://127.0.0.1:8080), lalu tab **Profil**. Setelah kode
Flutter diubah, ulangi build. Proxy hanya untuk pengembangan lokal dan meneruskan
`/accounts/` serta `/api/` ke Django. Untuk deployment, gunakan reverse proxy
yang sama origin atau konfigurasi CORS credentials, trusted CSRF origin, dan
cookie backend yang sesuai. Jangan menonaktifkan CSRF atau keamanan browser.

Jika Flutter melaporkan `Building with plugins requires symlink support` di
Windows, aktifkan **Developer Mode** pada Windows Settings, lalu ulangi
`flutter pub get`. Setelah dependensi sudah terunduh, pemeriksaan dan build web
dapat dijalankan dengan `--no-pub`. Secure storage pada web membutuhkan localhost
atau HTTPS. Dukungan Android minimal mengikuti Flutter SDK (plugin membutuhkan
API 23+); konfigurasi Keychain iOS dan izin jaringan macOS disertakan.

### Pengujian modul akun

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Tes mencakup kontrak form, CSRF dan rotasi cookie, pemulihan sesi pada instance
baru, validasi backend, edit profil, logout, input tidak valid, layar kecil,
serta regresi navigasi Jadwal/Edukasi. Tes integrasi backend bersifat opt-in dan
memakai **database di memori**, tanpa membuka `db.sqlite3` backend:

```powershell
# Terminal 1, dari root repo mobile; gunakan Python environment backend:
..\KelolaKita\env\Scripts\python.exe -B tool/account_test_server.py --backend ..\KelolaKita
# Terminal 2:
flutter test --no-pub --dart-define=ACCOUNT_TEST_URL=http://127.0.0.1:8765
```

Server uji akan memuat view/form/template Django asli dan membuat database baru
di memori. Hentikan server dengan Ctrl+C setelah pengujian. Lokasi virtualenv
backend dapat disesuaikan dengan mesin masing-masing.

## Anggota Kelompok

| No. | Nama | NPM |
|---|---|---|
| 1 | Glenn Josia Devano | 2506614712 |
| 2 | Ihsan Rafi Ahmad | 2506611326 |
| 3 | Maxwelly F.H. Simatupang | 2506584294 |
| 4 | Rafa Darussalam | 2506538924 |
| 5 | Rayna Kayla Rayvanka | 2506657283 |

---

## Peran Pengguna

### Pengguna

Pengguna merupakan pihak yang ingin menyetorkan barang atau sampah untuk mendapatkan penanganan yang sesuai. Pengguna dapat:

- Melakukan pengajuan penyetoran barang.
- Melihat hasil pemeriksaan dan kategori penanganan.
- Memilih metode penyetoran.
- Memilih lokasi titik setoran.
- Memilih jadwal penyetoran.
- Melihat lokasi panti atau titik penyaluran melalui peta.
- Memantau proses penjemputan dan penanganan barang.
- Mengakses informasi edukasi mengenai pengelolaan barang dan sampah.

### Pengelola KelolaKita

Pengelola merupakan pihak yang bertanggung jawab dalam menjalankan proses pemeriksaan, penyetoran, penjemputan, dan penanganan barang. Pengelola dapat:

- Melakukan pemeriksaan awal terhadap barang.
- Menentukan kategori penanganan barang.
- Mengelola titik setoran.
- Mengelola jadwal penyetoran.
- Mengelola proses penjemputan barang.
- Memverifikasi kondisi dan kategori barang.
- Mengelola proses penyaluran barang.
- Mengelola informasi dan konten edukasi.

### Pihak Mitra

KelolaKita dapat bekerja sama dengan pihak lain dalam proses penanganan barang, antara lain:

- **Bank sampah** untuk proses Recycle.
- **Panti asuhan** dan pihak yang membutuhkan untuk proses Reuse.
- **Komunitas** untuk mendukung proses penyaluran serta kegiatan Reduce dan Reuse.

---

## Daftar Modul

### 1. Authentication / Profile

Modul **Authentication / Profile** digunakan untuk mengelola identitas dan data pengguna KelolaKita.

**Cakupan fitur:**

- Registrasi dan login.
- Pengelolaan profil.
- Data pengguna.
- Informasi akun.
- Pengaturan akun.

**Operasi CRUD:**

| Operasi | Deskripsi |
|---|---|
| Create | Membuat akun dan data profil |
| Read | Melihat data profil |
| Update | Mengubah informasi profil |
| Delete | Menonaktifkan atau menghapus data akun |

**Penanggung Jawab:**  
`Rayna Kayla Rayvanka`

---

### 2. Pemeriksaan & Kategori Penanganan

Modul **Pemeriksaan & Kategori Penanganan** digunakan untuk menentukan metode penanganan berdasarkan jenis dan kondisi barang.

Setiap barang yang akan diproses wajib melalui pemeriksaan awal. Hasil pemeriksaan digunakan untuk menentukan apakah barang termasuk kategori **Recycle, Reduce, atau Reuse**.

**Cakupan fitur:**

- Pemeriksaan jenis barang.
- Pemeriksaan kondisi barang.
- Penentuan kategori penanganan.
- Informasi rekomendasi penanganan.
- Riwayat hasil pemeriksaan.

**Operasi CRUD:**

| Operasi | Deskripsi |
|---|---|
| Create | Membuat data pemeriksaan |
| Read | Melihat hasil pemeriksaan dan kategori penanganan |
| Update | Mengubah hasil pemeriksaan apabila diperlukan |
| Delete | Menghapus data pemeriksaan sesuai kewenangan |

**Penanggung Jawab:**  
`Rafa Darussalam`

---

### 3. Titik Setoran & Lokasi

Modul **Titik Setoran & Lokasi** digunakan untuk mengelola lokasi penyetoran dan membantu pengguna menemukan lokasi yang sesuai.

**Cakupan fitur:**

- Daftar titik setoran.
- Detail lokasi.
- Informasi alamat.
- Pencarian lokasi.
- Filter lokasi.
- Peta interaktif.
- Lokasi panti untuk penyaluran barang Reuse.

**Operasi CRUD:**

| Operasi | Deskripsi |
|---|---|
| Create | Menambahkan titik atau lokasi |
| Read | Melihat daftar, detail, dan lokasi pada peta |
| Update | Mengubah informasi lokasi |
| Delete | Menghapus lokasi yang tidak digunakan |

**Penanggung Jawab:**  
`Maxwelly F.H. Simatupang`

---

### 4. Penyetoran & Penjemputan

Modul **Penyetoran & Penjemputan** digunakan untuk mengatur proses penyetoran barang melalui kantor maupun titik setoran.

Pada metode **Setor ke Kantor**, pengguna membawa barang langsung ke kantor KelolaKita untuk menjalani pemeriksaan dan pengukuran. Setelah itu, barang ditentukan kategori penanganannya sebelum diproses lebih lanjut.

Pada metode **Setor ke Titik**, pengguna memilih lokasi titik setoran, menentukan kategori barang, memilih jadwal, dan melakukan konfirmasi. Setelah barang diletakkan sesuai jadwal, petugas akan melakukan penjemputan pada akhir sesi penyetoran.

Jadwal penyetoran terdiri atas dua sesi:

| Sesi | Waktu |
|---|---|
| Sesi Pagi | 08.00–11.00 |
| Sesi Siang | 13.00–16.00 |

**Operasi CRUD:**

| Operasi | Deskripsi |
|---|---|
| Create | Membuat permintaan penyetoran atau penjemputan |
| Read | Melihat detail dan status penyetoran |
| Update | Mengubah jadwal atau status sesuai kewenangan |
| Delete | Membatalkan permintaan yang masih dapat dibatalkan |

**Penanggung Jawab:**  
`Ihsan Rafi Ahmad`

---

### 5. Penyaluran, Komunitas & Edukasi

Modul **Penyaluran, Komunitas & Edukasi** digunakan untuk mendukung proses penanganan barang, khususnya pada kategori Reuse dan Reduce.

Pada kategori **Reuse**, barang yang masih layak digunakan dapat disalurkan melalui titik setoran, panti asuhan, komunitas, atau pihak lain yang membutuhkan. Barang berukuran besar dapat dialihkan kepada komunitas untuk membantu proses penyaluran.

Pada kategori **Reduce**, kegiatan difokuskan pada upaya mengurangi timbulan sampah melalui edukasi, kegiatan komunitas, kampanye pengurangan sampah, serta penggunaan produk yang dapat digunakan kembali.

**Contoh produk ramah lingkungan:**

- Tote bag.
- Stainless steel bottle.
- Reusable straw.
- Produk reusable lainnya.

**Operasi CRUD:**

| Operasi | Deskripsi |
|---|---|
| Create | Menambahkan data penyaluran, komunitas, atau konten edukasi |
| Read | Melihat informasi penyaluran, komunitas, dan edukasi |
| Update | Mengubah informasi yang tersedia |
| Delete | Menghapus data yang sudah tidak digunakan |

**Penanggung Jawab:**  
`Glenn Josia Devano`

---

## Alur Utama Sistem

KelolaKita menerapkan **pemeriksaan awal sebagai tahap utama sebelum barang diproses lebih lanjut**. Pengguna terlebih dahulu mengajukan barang yang ingin disetorkan. Barang tersebut kemudian diperiksa berdasarkan jenis dan kondisinya untuk menentukan kategori penanganan yang paling sesuai, yaitu Recycle, Reduce, atau Reuse.

Untuk barang yang masuk kategori **Recycle**, pengguna dapat memilih untuk menyetorkannya langsung ke kantor KelolaKita atau ke titik setoran yang tersedia. Jika memilih titik setoran, pengguna menentukan lokasi dan jadwal penyetoran. Setelah barang ditempatkan sesuai jadwal, petugas melakukan penjemputan dan membawa barang tersebut untuk diproses lebih lanjut sebelum disalurkan ke bank sampah.

Barang yang masuk kategori **Reuse** akan diarahkan untuk digunakan kembali. Barang berukuran kecil dapat disetorkan ke titik atau diantarkan langsung ke panti asuhan yang tersedia. Barang berukuran besar dapat disalurkan melalui komunitas agar dapat diteruskan kepada pihak yang membutuhkan.

Sementara itu, barang yang termasuk kategori **Reduce** tidak diarahkan ke proses daur ulang, tetapi ditangani melalui pendekatan pengurangan sampah. Pengguna akan mendapatkan informasi, edukasi, dan alternatif penggunaan produk yang dapat digunakan kembali. Komunitas juga dapat berperan dalam mendukung kegiatan dan kampanye untuk mengurangi timbulan sampah dari sumbernya.

Dengan alur tersebut, KelolaKita tidak hanya berfungsi sebagai tempat penyetoran barang, tetapi juga sebagai platform yang membantu pengguna menentukan **langkah penanganan yang sesuai untuk setiap barang berdasarkan jenis, kondisi, dan potensi pemanfaatannya**.

---

## Public API

KelolaKita menggunakan **ekosistem OpenStreetMap** untuk mendukung fitur yang membutuhkan informasi lokasi dan peta. Integrasi ini digunakan terutama pada modul **Titik Setoran & Lokasi**, serta mendukung proses penyetoran dan penyaluran barang berbasis lokasi.

### OpenStreetMap

**OpenStreetMap (OSM)** digunakan sebagai sumber peta dasar dan informasi geografis pada aplikasi KelolaKita. Peta digunakan untuk menampilkan lokasi titik setoran, kantor KelolaKita, serta lokasi penyaluran seperti panti yang berkaitan dengan proses Reuse. Informasi geografis tersebut membantu pengguna dalam melihat dan memilih lokasi yang sesuai berdasarkan kebutuhan penyetoran atau penyaluran barang.

Data titik setoran dan lokasi lain yang dikelola oleh KelolaKita tetap disimpan dalam database aplikasi. OpenStreetMap digunakan sebagai pendukung untuk menyediakan informasi geografis dan menampilkan peta pada antarmuka aplikasi.

Dokumentasi resmi:  
[OpenStreetMap API](https://wiki.openstreetmap.org/wiki/API)

### Nominatim

**Nominatim** digunakan oleh KelolaKita sebagai layanan **geocoding** untuk mengubah alamat atau nama lokasi menjadi koordinat geografis berupa latitude dan longitude. Layanan ini terutama digunakan ketika pengelola menambahkan atau memperbarui data titik setoran. Alamat yang dimasukkan akan diproses menggunakan Nominatim untuk memperoleh koordinat yang kemudian disimpan bersama data lokasi dan digunakan untuk menempatkan titik tersebut pada peta.

Penggunaan Nominatim membantu KelolaKita dalam menghubungkan informasi alamat dengan posisi geografis sehingga lokasi titik setoran dapat ditampilkan secara akurat pada peta dan digunakan dalam fitur pencarian lokasi.

Dokumentasi resmi:  
[Nominatim](https://nominatim.org/)

### Leaflet.js

**Leaflet.js** digunakan sebagai library JavaScript untuk menampilkan dan mengelola **peta interaktif** pada website KelolaKita. Leaflet memungkinkan aplikasi menampilkan marker lokasi, popup informasi, perpindahan dan pembesaran peta, serta interaksi lain yang dibutuhkan untuk membantu pengguna menemukan titik setoran dan lokasi penyaluran.

Dalam implementasinya, Leaflet digunakan bersama OpenStreetMap sebagai peta dasar. Koordinat yang diperoleh dari data lokasi KelolaKita maupun hasil geocoding Nominatim kemudian digunakan untuk menampilkan posisi masing-masing lokasi pada peta.

Dokumentasi resmi:  
[Leaflet.js](https://leafletjs.com/)

### Integrasi Public API

Ketiga teknologi tersebut digunakan secara saling melengkapi dalam fitur berbasis lokasi KelolaKita. **Nominatim** membantu memperoleh koordinat dari alamat, **OpenStreetMap** menyediakan peta dasar dan informasi geografis, sedangkan **Leaflet.js** digunakan untuk menampilkan peta tersebut secara interaktif pada website.

Integrasi ini terutama mendukung fitur pencarian dan pemilihan titik setoran, penampilan lokasi pada peta, serta proses penyaluran barang Reuse berdasarkan lokasi. KelolaKita tetap menyimpan data domain seperti titik setoran, jadwal, status penyetoran, dan informasi penyaluran pada database internal aplikasi.

---

## Ringkasan Fitur Utama

- Pemeriksaan awal barang sebelum diproses.
- Klasifikasi barang menjadi Recycle, Reduce, atau Reuse.
- Pilihan setor ke kantor atau titik setoran.
- Pemilihan lokasi dan jadwal penyetoran.
- Sistem penjemputan dari titik setoran.
- Peta untuk membantu pengguna menemukan lokasi.
- Penyaluran barang Reuse kepada pihak yang membutuhkan.
- Dukungan komunitas untuk proses Reduce dan Reuse.
- Edukasi mengenai pengelolaan dan pengurangan sampah.
- Informasi produk yang dapat digunakan kembali.
- Pengelolaan proses penanganan oleh pengelola KelolaKita.

---

## Tujuan Proyek

KelolaKita bertujuan membangun platform digital yang membantu masyarakat mengelola barang dan sampah dengan lebih terarah. Melalui proses pemeriksaan awal dan klasifikasi **Recycle, Reduce, dan Reuse**, setiap barang dapat diarahkan menuju metode penanganan yang sesuai dengan jenis dan kondisinya.

Platform ini diharapkan dapat membantu masyarakat membangun kebiasaan pengelolaan barang yang lebih bertanggung jawab sekaligus mempermudah proses penyetoran, penyaluran, dan edukasi mengenai pengelolaan sampah.

---

| Name | Link |
|---|---|
| Figma Design | [Edukasi Mobile](https://www.figma.com/design/E6eEv496fcyYML29RvCyhH?node-id=230-759) |
| Deployment |  |

## Integrasi Data Aplikasi Mobile dan Website (PWS)

Implementasi Checkpoint 1 untuk **Penyaluran, Komunitas & Edukasi** (Glenn Josia Devano) membaca JSON dari Django REST Framework. Website Django dan API menggunakan database yang sama. Buka **Edukasi** pada navigasi bawah untuk melihat artikel, agenda, dan catatan penyaluran. Pilih artikel untuk membaca isinya.

| Endpoint publik | Data |
|---|---|
| `GET /api/education/articles/` | Artikel terbit |
| `GET /api/education/articles/<slug>/` | Isi artikel terbit |
| `GET /api/education/events/` | Agenda terbit yang akan datang |
| `GET /api/education/distributions/` | Catatan penyaluran publik yang sudah selesai |

Endpoint daftar mengembalikan `count`, `next`, `previous`, dan `results`. Halaman Edukasi Checkpoint 1 menampilkan halaman pertama (maksimal 20 entri per daftar).

Untuk demo lokal, jalankan Django dari [repo KelolaKita](https://github.com/pbp-f-kelompok-1/KelolaKita) yang sudah memuat perubahan Checkpoint 1. Pasang dependensi dari `requirements.txt`, siapkan database pengembangan, lalu jalankan `python manage.py runserver`. Gunakan `API_BASE_URL=http://127.0.0.1:8000` saat menjalankan Flutter Web. Untuk Android debug, jalankan `adb reverse tcp:8000 tcp:8000` dan gunakan URL lokal yang sama pada `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000`.

Saat endpoint sudah tersedia di PWS, isi `API_BASE_URL` dengan URL HTTPS PWS pada `--dart-define`. Implementasi modul lain dan pengelolaan konten dari Flutter berada di luar Checkpoint 1 Edukasi.

## AI Disclosure

Dalam pengembangan KelolaKita, kelompok menggunakan beberapa perangkat AI sebagai **alat bantu** untuk mendukung proses eksplorasi ide, implementasi, debugging, pengujian, dan dokumentasi. Seluruh keputusan akhir, integrasi kode, serta validasi hasil tetap dilakukan oleh anggota kelompok.

### Tools yang Digunakan

| Tool | Tujuan Penggunaan |
|---|---|
| ChatGPT | Brainstorming fitur, penyusunan dokumentasi, dan bantuan troubleshooting |
| OpenAI Codex | Saran implementasi, refactoring, penyusunan test case, dan analisis perubahan kode |
| Claude Code | Bantuan implementasi modul, penelusuran codebase, debugging, dan code review |
| DeepSeek V4.1 Flash | Alternatif analisis solusi, debugging, dan pemeriksaan logika program |
| Gemini | Pemberian alternatif pendekatan, review kode, dan penyempurnaan dokumentasi |
| Figma AI | Eksplorasi layout, komponen, dan konsistensi awal design system |

### Ruang Lingkup Penggunaan

AI digunakan untuk membantu kegiatan berikut:

- mengeksplorasi alternatif desain dan alur fitur;
- memberikan saran struktur model, form, view, template, dan JavaScript;
- membantu menemukan penyebab error dan kemungkinan solusi;
- menyusun atau memperluas unit test;
- membantu merapikan dokumentasi teknis;
- memberikan masukan saat proses refactoring dan integrasi antarmodul.

Secara umum, kelompok memberikan konteks modul, ruang lingkup file, kebutuhan fitur, batasan keamanan, dan hasil yang diharapkan. Permintaan dipecah menjadi tugas-tugas kecil agar keluaran dapat diperiksa sebelum digabungkan ke codebase utama.

### Verifikasi dan Perbaikan Manual

Keluaran AI tidak langsung digunakan tanpa pemeriksaan. Kelompok melakukan:

- pemeriksaan perubahan melalui Git diff dan Pull Request;
- penyesuaian manual terhadap struktur dan konvensi codebase;
- pemeriksaan ulang URL, validasi form, autentikasi, dan otorisasi;
- penyelesaian conflict serta integrasi dengan modul anggota lain;
- pengujian melalui `manage.py check`, unit test, dan pengujian manual di browser;
- pemeriksaan responsivitas, konsistensi design system, serta hasil build Tailwind.

### Keterbatasan AI

Perangkat AI dapat menghasilkan asumsi yang tidak sesuai dengan kondisi branch terbaru, nama URL atau dependensi yang keliru, perubahan yang terlalu luas, maupun kode yang terlihat benar tetapi belum terintegrasi. Perbedaan rekomendasi antartools juga dapat terjadi. Oleh karena itu, kelompok membandingkan keluaran AI dengan kebutuhan proyek, dokumentasi resmi, kondisi codebase, dan hasil pengujian sebelum menerima suatu perubahan.

AI tidak diberi kewenangan untuk menentukan keputusan produk atau melakukan merge dan deployment tanpa pemeriksaan anggota kelompok. Kredensial, password, token, serta data sensitif produksi tidak dimasukkan ke dalam prompt.

## Batasan dan Pengembangan Lanjutan

- Persistensi file media pada environment PWS masih perlu diverifikasi untuk penggunaan jangka panjang.
- Penghapusan file gambar lama belum seluruhnya otomatis ketika record dihapus.
- Modul tertentu masih menggunakan otorisasi group-level dan dapat dikembangkan menjadi object-level permission yang lebih granular.
- Penghapusan akun secara mandiri belum diekspos sebagai fitur publik; penghapusan `User` oleh pengelola menghapus `Profile` terkait melalui `CASCADE`.
- Audit log, rate limiting, notifikasi, dan soft delete dapat ditambahkan pada iterasi berikutnya.
- Pipeline CI/CD otomatis belum tersedia; deployment saat ini dilakukan secara manual setelah review dan pengujian.

---

KelolaKita Mobile dikembangkan sebagai Proyek Akhir Semester mata kuliah Pemrograman Berbasis Platform, Fakultas Ilmu Komputer, Universitas Indonesia.
