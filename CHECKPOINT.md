# WARUNG RAFHA - PROJECT CHECKPOINT
Tanggal: Selasa, 28 Juli 2026
Tujuan File: File ini adalah rangkuman 9 file inti, jadi context utama tiap sesi baru. Update file ini setiap ada perubahan fitur.

## 1. VISI APLIKASI
Aplikasi **WaroengKU** adalah sistem manajemen operasional ritel (warung/toko) modern berbasis Flutter dan SQLite. Aplikasi ini dirancang untuk mendigitalisasi operasional harian warung secara mandiri, aman, dan efisien dengan fokus utama pada:
*   **Keamanan Akses**: Sistem otentikasi berbasis PIN 6 digit unik serta pembatasan akses ketat berdasarkan peran (*role-based access control*).
*   **Transparansi & Kedisiplinan**: Sistem mesin absensi karyawan yang dilengkapi dengan swafoto (selfie) menggunakan kamera depan untuk mencegah kecurangan.
*   **Pengawasan Real-Time**: "CCTV Digital" atau ruang log aktivitas yang mencatat setiap tindakan operasional penting yang dilakukan di warung.
*   **Otomatisasi Finansial**: Fitur Auto-Payroll (penggajian) terintegrasi dengan pengelolaan hutang kasbon karyawan secara instan.
*   **Manajemen Inventaris**: Pengelolaan barang gudang dengan pembatasan hak lihat harga modal & supplier demi kerahasiaan bisnis pemilik toko.

---

## 2. STRUKTUR DATABASE (SQLite - `waroengku.db` Versi 8)
Database lokal SQLite ini dikelola melalui `DatabaseHelper` dengan rincian 9 tabel utama sebagai berikut:

### 1. Tabel `pelanggan`
Menyimpan data identitas, alamat, loyalitas (poin), serta catatan hutang pelanggan.
*   `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
*   `nama`: `TEXT NOT NULL`
*   `no_wa`: `TEXT NOT NULL`
*   `tanggal_lahir`: `TEXT`
*   `alamat`: `TEXT`
*   `poin`: `INTEGER DEFAULT 0`
*   `total_kasbon`: `REAL DEFAULT 0.0`
*   `created_at`: `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`

### 2. Tabel `karyawan`
Menyimpan profil, status kepegawaian, PIN otentikasi, gaji, sisa kasbon, dan tingkat level akses karyawan.
*   `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
*   `nama`: `TEXT NOT NULL`
*   `pin`: `TEXT NOT NULL UNIQUE`
*   `role`: `TEXT NOT NULL` (Misal: `BOS`, `KASIR`, `LAPANGAN`)
*   `status_aktif`: `INTEGER DEFAULT 1` (1 = Aktif, 0 = Diblokir)
*   `foto_profil`: `TEXT DEFAULT ""` (Path file)
*   `foto_ktp`: `TEXT DEFAULT ""` (Path file)
*   `alamat`: `TEXT DEFAULT ""`
*   `gaji`: `REAL DEFAULT 0.0`
*   `kasbon`: `REAL DEFAULT 0.0`
*   `tgl_mulai`: `TEXT DEFAULT ""`
*   `shift`: `TEXT DEFAULT ""` (Shift harian: Pagi, Siang, dll)
*   `hak_akses`: `TEXT DEFAULT "[]"` (Array JSON)
*   `nama_level`: `TEXT DEFAULT "Level 1"`
*   `created_at`: `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
*   *Catatan*: Saat database pertama kali dibuat, akun default Bos disisipkan secara otomatis (`nama`: 'Bos Rafha', `pin`: '123456', `role`: 'BOS', `hak_akses`: '["ALL"]', `nama_level`: 'BOS').

### 3. Tabel `barang`
Gudang penyimpanan barang yang berisi detail produk, harga modal (sensitif), harga jual, stok, serta foto produk (multi-image).
*   `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
*   `barcode`: `TEXT NOT NULL UNIQUE`
*   `nama_barang`: `TEXT NOT NULL`
*   `harga_modal`: `REAL NOT NULL` (Hanya boleh dilihat oleh `BOS`)
*   `harga_jual`: `REAL NOT NULL`
*   `stok`: `INTEGER DEFAULT 0`
*   `deskripsi`: `TEXT DEFAULT ""`
*   `kategori`: `TEXT DEFAULT ""`
*   `produsen`: `TEXT DEFAULT ""`
*   `supplier`: `TEXT DEFAULT ""` (Hanya boleh dilihat oleh `BOS`)
*   `no_nota`: `TEXT DEFAULT ""` (Hanya boleh dilihat oleh `BOS`)
*   `foto_produk`: `TEXT DEFAULT "[]"` (JSON array yang menyimpan path gambar lokal)
*   `created_at`: `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`

### 4. Tabel `lembur`
Mencatat tanggal dan durasi lembur karyawan untuk dihitung pada penggajian.
*   `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
*   `id_karyawan`: `INTEGER NOT NULL`
*   `tanggal`: `TEXT NOT NULL`
*   `durasi_jam`: `REAL DEFAULT 0.0`
*   `keterangan`: `TEXT DEFAULT ""`
*   `created_at`: `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`

### 5. Tabel `level_akses`
Mengatur daftar izin akses yang dapat diberikan secara fleksibel kepada kelompok atau tingkatan karyawan tertentu.
*   `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
*   `nama_level`: `TEXT NOT NULL UNIQUE` (Default: `Level 1` dan `Level 2`)
*   `daftar_akses`: `TEXT DEFAULT "[]"` (JSON array dari kumpulan string izin kustom)

### 6. Tabel `absensi`
Mencatat log kehadiran harian karyawan, lengkap dengan jam masuk/pulang serta bukti foto kamera depan.
*   `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
*   `id_karyawan`: `INTEGER NOT NULL`
*   `tanggal`: `TEXT NOT NULL`
*   `jam_masuk`: `TEXT`
*   `jam_pulang`: `TEXT`
*   `foto_masuk`: `TEXT` (Path file swafoto masuk)
*   `foto_pulang`: `TEXT` (Path file swafoto pulang)

### 7. Tabel `log_aktivitas` (CCTV Digital)
Merekam histori operasional harian yang terjadi dalam aplikasi secara otomatis untuk tujuan pengawasan.
*   `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
*   `nama_karyawan`: `TEXT`
*   `aktivitas`: `TEXT`
*   `waktu`: `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`

### 8. Tabel `cuti`
Pencatatan pengajuan cuti beserta statusnya.
*   `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
*   `id_karyawan`: `INTEGER NOT NULL`
*   `tgl_mulai`: `TEXT`
*   `tgl_selesai`: `TEXT`
*   `alasan`: `TEXT`
*   `status`: `TEXT DEFAULT "PENDING"`

### 9. Tabel `penggajian`
Menyimpan arsip atau riwayat transaksi penggajian karyawan yang telah dicairkan oleh Bos.
*   `id`: `INTEGER PRIMARY KEY AUTOINCREMENT`
*   `id_karyawan`: `INTEGER NOT NULL`
*   `periode_bulan`: `TEXT` (Format: MMMM yyyy)
*   `gaji_pokok`: `REAL`
*   `bonus_lembur`: `REAL`
*   `potongan_kasbon`: `REAL`
*   `gaji_bersih`: `REAL`
*   `tanggal_cair`: `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`

---

## 3. DETAIL PER FILE (Analisis 9 File Inti)

### 1. `main.dart`
*   **Fitur**: Titik masuk utama (*entry point*) aplikasi Flutter.
*   **Fungsi Kunci**: 
    *   `WidgetsFlutterBinding.ensureInitialized()` menjamin persiapan interface native berjalan lancar.
    *   `initializeDateFormatting('id_ID', null)` mendaftarkan kalender & penanggalan lokal Bahasa Indonesia (untuk mesin absensi).
*   **Validasi & State**: Mengarahkan halaman awal ke `LoginScreen()`.

### 2. `database_helper.dart`
*   **Fitur**: Manajemen SQLite database, inisialisasi schema, peningkatan versi (*upgrade path*), dan kumpulan fungsi CRUD lengkap.
*   **Fungsi Kunci**: 
    *   `_initDB` & `_createDB` mengatur pembuatan tabel awal serta memasukkan data default Bos dan Level Akses (Level 1 & Level 2).
    *   `_upgradeDB` mengimplementasikan siklus evolusi schema database hingga versi 8 (menambahkan kasbon, penggajian, cctv, dll).
    *   `cairkanGaji` menyimpan entri slip gaji ke tabel `penggajian`, mengurangi sisa kasbon di profil karyawan terkait, serta menulis log aktivitas sistem.
*   **Validasi & State**: Validasi PIN login karyawan hanya diperbolehkan jika status karyawan aktif (`status_aktif = 1`).

### 3. `login_screen.dart`
*   **Fitur**: Layar otentikasi PIN 6 digit bagi seluruh peran pengguna.
*   **Fungsi Kunci**: 
    *   `_tekanTombol` & `_onKeyboardTyping` mendukung input ganda melalui tombol numerik kustom pada layar (*custom numpad*) atau keyboard fisik/bawaan HP (melalui `TextField` transparan).
    *   `_prosesLogin` memproses otentikasi serta menulis histori log ke CCTV Digital jika berhasil.
*   **Validasi & State**: 
    *   Otomatis memproses login begitu input menyentuh **6 digit** (*auto-submit*).
    *   Jika PIN salah atau akun karyawan berstatus diblokir, input langsung dikosongkan dan menampilkan SnackBar kesalahan.

### 4. `dashboard_screen.dart`
*   **Fitur**: Menu navigasi pusat operasional aplikasi yang menyesuaikan hak akses berdasarkan peran akun yang login (*Role-Based Menu*).
*   **Fungsi Kunci**: 
    *   `_buildMenuCard` membangun kartu navigasi interaktif.
    *   Menyediakan tombol Logout cepat pada AppBar yang mengganti navigasi kembali ke `LoginScreen()`.
*   **Validasi & State**: Membatasi tampilan menu tertentu berdasarkan parameter `role` (Misal: Menu "Auto-Payroll" dan "Kelola Karyawan" hanya ditampilkan bila `role == 'BOS'`).

### 5. `absensi_screen.dart`
*   **Fitur**: Mesin absensi mandiri karyawan berbasis swafoto kamera depan harian.
*   **Fungsi Kunci**: 
    *   `_cekStatusAbsen` memeriksa record absen hari ini di database saat inisialisasi layar.
    *   `_prosesAbsen` mengoordinasikan pengambilan gambar, penyimpanan waktu jam & tanggal, serta pencatatan log.
*   **Validasi & State**:
    *   **Selfie Kamera Depan**: Pengambilan gambar wajib menggunakan kamera depan (`preferredCameraDevice: CameraDevice.front`) dengan kualitas yang dipadatkan (`imageQuality: 60`).
    *   **Batal Absen**: Jika pengambilan gambar dibatalkan (`photo == null`), seluruh proses dihentikan agar karyawan tidak bisa melakukan manipulasi jam absensi tanpa bukti fisik foto.
    *   **State Absensi**: Terdiri dari 3 fase visual statis (Belum Absen, Sedang Bekerja, Absensi Selesai).

### 6. `data_barang_screen.dart`
*   **Fitur**: Manajemen stok inventaris gudang toko dilengkapi pembaca barcode.
*   **Fungsi Kunci**: 
    *   `_scanDanTambahBarang` meluncurkan kamera untuk memindai barcode menggunakan `BarcodeScanner`.
    *   `_tampilkanForm` mengoordinasikan input data barang kustom dengan *Autocomplete* pintar untuk kategori, produsen, dan supplier.
    *   `CurrencyInputFormatter` memformat isian nominal rupiah secara real-time demi kemudahan isian input numerik.
*   **Validasi & State (Filter Role)**:
    *   Tombol Edit produk hanya ditampilkan jika `role == 'BOS'`.
    *   Isian dan tampilan data "Harga Modal", "Supplier", serta "No Nota" disembunyikan seluruhnya dari role selain **`BOS`**.
    *   Fungsi `_singkatBarcode` menyamarkan kode barcode menjadi bentuk terkompresi (3 karakter awal + 5 karakter akhir) khusus untuk role di luar **`BOS`** guna mencegah kebocoran database inventaris.

### 7. `kelola_karyawan_screen.dart`
*   **Fitur**: Pusat kendali karyawan bagi Bos untuk melakukan manajemen staf dan pendelegasian wewenang level akses.
*   **Fungsi Kunci**: 
    *   `_tampilkanFormKaryawan` & `_ubahStatusKaryawan` melakukan pendaftaran, perbaruan biodata, serta pemblokiran staf.
    *   `ManajemenLevelScreen` (Pusat Kendali Level) bertindak sebagai modul CRUD tingkat level izin secara modular (input/hapus barang, pelanggan, kasbon, laporan).
*   **Validasi & State**:
    *   Menyaring keluar akun `BOS` dari daftar edit agar pemilik utama tidak sengaja dinonaktifkan atau diubah profilnya.
    *   Mewajibkan isian PIN 6 digit unik untuk mencegah bentrokan kredensial antar karyawan saat login.
    *   Status nonaktif/blokir secara instan menghentikan hak masuk sistem pada file `login_screen.dart`.

### 8. `payroll_screen.dart`
*   **Fitur**: Penggajian otomatis (*Auto-Payroll*) staf warung terintegrasi dengan pencatatan dan pemotongan hutang kasbon.
*   **Fungsi Kunci**: 
    *   `_tambahKasbon` menambahkan pencatatan piutang kasbon karyawan secara terpisah.
    *   `_hitungGaji` memicu popup dialog slip gaji dinamis harian yang menghitung total pendapatan bersih staf secara real-time.
*   **Validasi & State**:
    *   Mengecualikan user `BOS` dari sistem penggajian.
    *   **Validasi Potongan Kasbon**: Nilai potongan yang dimasukkan saat pencairan gaji tidak boleh melebihi sisa hutang kasbon riil karyawan di database demi menghindari salah hitung saldo.

### 9. `pengawasan_screen.dart`
*   **Fitur**: Ruang monitoring terpadu operasional bagi Bos (Monitoring Absensi & CCTV Digital).
*   **Fungsi Kunci**: 
    *   `_lihatFotoSelfie` menampilkan pop-up audit visual foto selfie masuk dan pulang karyawan hari ini dari file media lokal.
*   **Validasi & State**: Tombol "Lihat" foto selfie pulang hanya aktif jika karyawan telah merekam waktu absen pulangnya (`absen['jam_pulang'] != null`).

---

## 4. ROLE MATRIX (Matriks Peran & Hak Akses)

| Fitur / Halaman | BOS | KASIR | LAPANGAN | Keterangan |
| :--- | :---: | :---: | :---: | :--- |
| **Login PIN 6 Digit** | Ya | Ya | Ya | Diperlukan PIN aktif untuk semua peran. |
| **Mesin Absensi** | Ya | Ya | Ya | Semua peran wajib melakukan swafoto absensi harian. |
| **Kasir Utama** | Ya | Ya | - | Hanya diizinkan bagi Bos dan peran Kasir. |
| **QR Estafet** | Ya | - | Ya | Hanya diizinkan bagi Bos dan peran Lapangan. |
| **Data Pelanggan** | Ya | Ya | Ya | Menu umum operasional harian. |
| **Lihat Harga Modal & Supplier** | Ya | - | - | Disembunyikan penuh dari Kasir & Lapangan demi rahasia dapur warung. |
| **Ubah / Tambah Data Barang** | Ya | - | - | Hanya Bos yang memiliki wewenang mengelola data produk dasar. |
| **Masking Barcode (Kode BC)**| Tidak | Ya | Ya | Kode barcode disamarkan bagi staf agar tidak disalin sembarangan. |
| **CCTV & Absen** | Ya | - | - | Pemantauan penuh log aktivitas warung. |
| **Auto-Payroll & Kasbon** | Ya | - | - | Pengelolaan penggajian, pemotongan kasbon, dan pencatatan piutang staf. |
| **Kelola Karyawan & Hak Akses**| Ya | - | - | Pendaftaran staf, pemblokiran akun, dan pembuatan izin level akses kustom. |
| **Laporan Penjualan** | Ya | - | - | Hak eksklusif milik Bos untuk memantau neraca keuntungan. |

---

## 5. ALUR UTAMA PENGGUNAAN APLIKASI
```
[ Login Screen ] 
       │ 
       ▼ (PIN 6 Digit Dicocokkan + Status Aktif Divalidasi)
[ Dashboard Screen (Menu menyesuaikan Role) ]
       │
       ├─► [ Mesin Absensi ] ──► (Selfie depan wajib) ──► Absen Masuk / Pulang
       │
       ├─► [ Data Barang ] ───► (BOS: CRUD lengkap + Harga Modal)
       │                        (Staff: View Only + Masking Barcode & Modal)
       │
       ├─► [ Kelola Karyawan ] (Khusus BOS: CRUD staff + Blokir akun + CRUD Level Akses)
       │
       ├─► [ Auto-Payroll ] ──► (Khusus BOS: Input lembur, cicil/tambah kasbon, Cairkan Gaji)
       │
       └─► [ CCTV & Absen ] ──► (Khusus BOS: Audit foto selfie + Inspeksi Log Histori Aktivitas)
```

---

## 6. RUMUS & LOGIKA OPERASIONAL PENTING

### 1. Perhitungan Gaji Bersih (Auto-Payroll)
Gaji bersih bulanan dihitung secara interaktif dalam popup dialog `_hitungGaji` pada `payroll_screen.dart` menggunakan rumus:
$$\text{Gaji Bersih} = (\text{Gaji Pokok} + \text{Tambahan Lembur/Bonus}) - \text{Potongan Kasbon}$$

*   **Gaji Pokok**: Diambil dari data profil karyawan.
*   **Tambahan Lembur/Bonus**: Isian interaktif Bos (bernilai default `0`).
*   **Potongan Kasbon**: Otomatis terisi default senilai total hutang kasbon karyawan, namun Bos dapat menguranginya jika karyawan mencicil sebagian.
*   *Validasi*: $\text{Potongan Kasbon} \le \text{Kasbon Aktif Karyawan}$.

### 2. Status Siklus Absensi (Absensi 3 Fase)
Mesin absensi mendeteksi kehadiran harian karyawan secara dinamis berdasarkan 3 fase:
1.  **Fase 1 (Belum Masuk)**: Record kehadiran hari ini tidak ditemukan di database (`dataAbsenHariIni == null`). Tombol "Absen MASUK" aktif.
2.  **Fase 2 (Sedang Bekerja)**: Record absen hari ini ditemukan tetapi jam pulang masih kosong (`dataAbsenHariIni != null && dataAbsenHariIni['jam_pulang'] == null`). Tombol "Absen PULANG" aktif.
3.  **Fase 3 (Absensi Selesai)**: Record absensi lengkap terisi (`jam_masuk` dan `jam_pulang` terisi). Seluruh tombol absen dinonaktifkan.

### 3. Masking Kode Barcode Toko
Untuk role selain `BOS`, string barcode disamarkan melalui fungsi `_singkatBarcode`:
*   Karakter tanda kurung `(` dan `)` dihilangkan.
*   Jika panjang barcode > 8 karakter, sistem memotong dan menggabungkan **3 karakter pertama** dengan **5 karakter terakhir** untuk meminimalkan pembacaan barcode internal toko secara ilegal oleh staff.

---

## 7. CATATAN KEAMANAN & INTEGRITAS DATA
*   **Otorisasi Log Masuk**: PIN karyawan disimpan dalam database lokal SQLite (`waroengku.db`). PIN bersifat unik (`UNIQUE`) untuk memastikan tidak terjadi tumpang tindih otentikasi.
*   **Penyegelan Akun (Blokir)**: Saat status karyawan diubah menjadi nonaktif (`status_aktif = 0`), karyawan tersebut secara instan ditolak masuk sistem pada layer `cekLogin` di `DatabaseHelper`, bahkan jika mereka memasukkan PIN yang benar.
*   **Pencegahan Kecurangan Absensi**: Swafoto absensi wajib dipotret secara real-time melalui integrasi kamera depan (`preferredCameraDevice: CameraDevice.front`) dan melarang pengunggahan berkas media dari galeri lokal HP. 
*   **Audit Trail Operasional**: Setiap tindakan sensitif (seperti: Login Sukses, Absen Masuk/Pulang, Blokir Akun, Tambah Kasbon, Cairkan Gaji) langsung ditandai dengan stempel waktu harian dan dicatat permanen ke tabel `log_aktivitas` untuk diinspeksi oleh Bos sewaktu-waktu.

---

## 8. CHANGELOG / TODO
*(Bagian ini akan diperbarui secara berkala pada setiap akhir sesi pengembangan)*

```markdown
- [2026-07-28] Pembuatan checkpoint utama (Otak Utama) yang mendokumentasikan 9 file dasar arsitektur WaroengKU.
- [TODO] Implementasi menu "Kasir Utama" yang terintegrasi dengan transaksi penjualan.
- [TODO] Implementasi menu "QR Estafet" untuk operasional peran Lapangan.
- [TODO] Implementasi menu "Laporan Penjualan" lengkap dengan analisis margin keuntungan bagi peran BOS.
- [TODO] Implementasi integrasi sistem pengelolaan "Data Pelanggan" lengkap dengan sistem pengumpulan Poin loyalitas.
```
