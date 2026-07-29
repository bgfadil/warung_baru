import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('waroengku.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8, // DATABASE VERSI 8
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Pelanggan
    await db.execute(
        'CREATE TABLE pelanggan (id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT NOT NULL, no_wa TEXT NOT NULL, tanggal_lahir TEXT, alamat TEXT, poin INTEGER DEFAULT 0, total_kasbon REAL DEFAULT 0.0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');

    // 2. Tabel Karyawan
    await db.execute(
        'CREATE TABLE karyawan (id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT NOT NULL, pin TEXT NOT NULL UNIQUE, role TEXT NOT NULL, status_aktif INTEGER DEFAULT 1, foto_profil TEXT DEFAULT "", foto_ktp TEXT DEFAULT "", alamat TEXT DEFAULT "", gaji REAL DEFAULT 0.0, kasbon REAL DEFAULT 0.0, tgl_mulai TEXT DEFAULT "", shift TEXT DEFAULT "", hak_akses TEXT DEFAULT "[]", nama_level TEXT DEFAULT "Level 1", created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.insert('karyawan', {
      'nama': 'Bos Rafha',
      'pin': '123456',
      'role': 'BOS',
      'status_aktif': 1,
      'hak_akses': '["ALL"]',
      'nama_level': 'BOS'
    });

    // 3. Tabel Barang
    await db.execute(
        'CREATE TABLE barang (id INTEGER PRIMARY KEY AUTOINCREMENT, barcode TEXT NOT NULL UNIQUE, nama_barang TEXT NOT NULL, harga_modal REAL NOT NULL, harga_jual REAL NOT NULL, stok INTEGER DEFAULT 0, deskripsi TEXT DEFAULT "", kategori TEXT DEFAULT "", produsen TEXT DEFAULT "", supplier TEXT DEFAULT "", no_nota TEXT DEFAULT "", foto_produk TEXT DEFAULT "[]", created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');

    // 4. Tabel Lembur
    await db.execute(
        'CREATE TABLE lembur (id INTEGER PRIMARY KEY AUTOINCREMENT, id_karyawan INTEGER NOT NULL, tanggal TEXT NOT NULL, durasi_jam REAL DEFAULT 0.0, keterangan TEXT DEFAULT "", created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');

    // 5. Tabel Level Akses
    await db.execute(
        'CREATE TABLE level_akses (id INTEGER PRIMARY KEY AUTOINCREMENT, nama_level TEXT NOT NULL UNIQUE, daftar_akses TEXT DEFAULT "[]")');
    await db.insert('level_akses', {
      'nama_level': 'Level 1',
      'daftar_akses': '["input_barang", "input_pelanggan"]'
    });
    await db.insert('level_akses', {
      'nama_level': 'Level 2',
      'daftar_akses':
          '["input_barang", "input_pelanggan", "kasbon", "lihat_laporan"]'
    });

    // 6. Tabel Absensi, CCTV, & Cuti
    await db.execute(
        'CREATE TABLE absensi (id INTEGER PRIMARY KEY AUTOINCREMENT, id_karyawan INTEGER NOT NULL, tanggal TEXT NOT NULL, jam_masuk TEXT, jam_pulang TEXT, foto_masuk TEXT, foto_pulang TEXT)');
    await db.execute(
        'CREATE TABLE log_aktivitas (id INTEGER PRIMARY KEY AUTOINCREMENT, nama_karyawan TEXT, aktivitas TEXT, waktu TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    await db.execute(
        'CREATE TABLE cuti (id INTEGER PRIMARY KEY AUTOINCREMENT, id_karyawan INTEGER NOT NULL, tgl_mulai TEXT, tgl_selesai TEXT, alasan TEXT, status TEXT DEFAULT "PENDING")');

    // 7. Tabel Penggajian
    await db.execute(
        'CREATE TABLE penggajian (id INTEGER PRIMARY KEY AUTOINCREMENT, id_karyawan INTEGER NOT NULL, periode_bulan TEXT, gaji_pokok REAL, bonus_lembur REAL, potongan_kasbon REAL, gaji_bersih REAL, tanggal_cair TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'CREATE TABLE barang (id INTEGER PRIMARY KEY AUTOINCREMENT, barcode TEXT NOT NULL UNIQUE, nama_barang TEXT NOT NULL, harga_modal REAL NOT NULL, harga_jual REAL NOT NULL, stok INTEGER DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    }
    if (oldVersion < 3) {
      await db
          .execute('ALTER TABLE barang ADD COLUMN deskripsi TEXT DEFAULT ""');
      await db
          .execute('ALTER TABLE barang ADD COLUMN kategori TEXT DEFAULT ""');
      await db
          .execute('ALTER TABLE barang ADD COLUMN produsen TEXT DEFAULT ""');
      await db
          .execute('ALTER TABLE barang ADD COLUMN supplier TEXT DEFAULT ""');
      await db.execute('ALTER TABLE barang ADD COLUMN no_nota TEXT DEFAULT ""');
      await db.execute(
          'ALTER TABLE barang ADD COLUMN foto_produk TEXT DEFAULT "[]"');
    }
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE karyawan ADD COLUMN foto_profil TEXT DEFAULT ""');
      await db
          .execute('ALTER TABLE karyawan ADD COLUMN foto_ktp TEXT DEFAULT ""');
      await db
          .execute('ALTER TABLE karyawan ADD COLUMN alamat TEXT DEFAULT ""');
      await db.execute('ALTER TABLE karyawan ADD COLUMN gaji REAL DEFAULT 0.0');
      await db
          .execute('ALTER TABLE karyawan ADD COLUMN tgl_mulai TEXT DEFAULT ""');
      await db.execute('ALTER TABLE karyawan ADD COLUMN shift TEXT DEFAULT ""');
      await db.execute(
          'CREATE TABLE lembur (id INTEGER PRIMARY KEY AUTOINCREMENT, id_karyawan INTEGER NOT NULL, tanggal TEXT NOT NULL, durasi_jam REAL DEFAULT 0.0, keterangan TEXT DEFAULT "", created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    }
    if (oldVersion < 5) {
      await db.execute(
          'ALTER TABLE karyawan ADD COLUMN hak_akses TEXT DEFAULT "[]"');
    }
    if (oldVersion < 6) {
      await db.execute(
          'CREATE TABLE level_akses (id INTEGER PRIMARY KEY AUTOINCREMENT, nama_level TEXT NOT NULL UNIQUE, daftar_akses TEXT DEFAULT "[]")');
      await db.insert('level_akses', {
        'nama_level': 'Level 1',
        'daftar_akses': '["input_barang", "input_pelanggan"]'
      });
      await db.insert('level_akses', {
        'nama_level': 'Level 2',
        'daftar_akses':
            '["input_barang", "input_pelanggan", "kasbon", "lihat_laporan"]'
      });
      await db.execute(
          'ALTER TABLE karyawan ADD COLUMN nama_level TEXT DEFAULT "Level 1"');
    }
    if (oldVersion < 7) {
      await db.execute(
          'CREATE TABLE absensi (id INTEGER PRIMARY KEY AUTOINCREMENT, id_karyawan INTEGER NOT NULL, tanggal TEXT NOT NULL, jam_masuk TEXT, jam_pulang TEXT, foto_masuk TEXT, foto_pulang TEXT)');
      await db.execute(
          'CREATE TABLE log_aktivitas (id INTEGER PRIMARY KEY AUTOINCREMENT, nama_karyawan TEXT, aktivitas TEXT, waktu TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
      await db.execute(
          'CREATE TABLE cuti (id INTEGER PRIMARY KEY AUTOINCREMENT, id_karyawan INTEGER NOT NULL, tgl_mulai TEXT, tgl_selesai TEXT, alasan TEXT, status TEXT DEFAULT "PENDING")');
    }
    if (oldVersion < 8) {
      await db
          .execute('ALTER TABLE karyawan ADD COLUMN kasbon REAL DEFAULT 0.0');
      await db.execute(
          'CREATE TABLE penggajian (id INTEGER PRIMARY KEY AUTOINCREMENT, id_karyawan INTEGER NOT NULL, periode_bulan TEXT, gaji_pokok REAL, bonus_lembur REAL, potongan_kasbon REAL, gaji_bersih REAL, tanggal_cair TIMESTAMP DEFAULT CURRENT_TIMESTAMP)');
    }
  }

  // ========================================================
  // KUMPULAN FUNGSI CRUD LENGKAP
  // ========================================================

  // --- PELANGGAN ---
  Future<int> tambahPelanggan(Map<String, dynamic> data) async =>
      await (await instance.database).insert('pelanggan', data);
  Future<List<Map<String, dynamic>>> getSemuaPelanggan() async =>
      await (await instance.database).query('pelanggan', orderBy: 'nama ASC');
  Future<List<Map<String, dynamic>>> cariPelanggan(String keyword) async =>
      await (await instance.database).query('pelanggan',
          where: 'no_wa LIKE ? OR nama LIKE ?',
          whereArgs: ['%$keyword%', '%$keyword%']);

  // --- KARYAWAN & LOGIN ---
  Future<Map<String, dynamic>?> cekLogin(String inputPin) async {
    final hasil = await (await instance.database).query('karyawan',
        where: 'pin = ? AND status_aktif = 1', whereArgs: [inputPin]);
    return hasil.isNotEmpty ? hasil.first : null;
  }

  Future<List<Map<String, dynamic>>> getSemuaKaryawan() async =>
      await (await instance.database).query('karyawan', orderBy: 'nama ASC');
  Future<int> tambahKaryawan(Map<String, dynamic> data) async =>
      await (await instance.database).insert('karyawan', data);
  Future<int> updateKaryawan(int id, Map<String, dynamic> data) async =>
      await (await instance.database)
          .update('karyawan', data, where: 'id = ?', whereArgs: [id]);
  Future<int> bosResetPin(int id, String pinBaru) async =>
      await (await instance.database).update('karyawan', {'pin': pinBaru},
          where: 'id = ?', whereArgs: [id]);

  // --- BARANG (YANG TADI SEMPAT TERHAPUS) ---
  Future<int> tambahBarang(Map<String, dynamic> data) async =>
      await (await instance.database).insert('barang', data);
  Future<int> updateBarang(int id, Map<String, dynamic> data) async =>
      await (await instance.database)
          .update('barang', data, where: 'id = ?', whereArgs: [id]);
  Future<int> hapusBarang(int id) async => await (await instance.database)
      .delete('barang', where: 'id = ?', whereArgs: [id]);
  Future<List<Map<String, dynamic>>> getSemuaBarang() async =>
      await (await instance.database)
          .query('barang', orderBy: 'nama_barang ASC');
  Future<Map<String, dynamic>?> cariBarangByBarcode(String barcode) async {
    final hasil = await (await instance.database)
        .query('barang', where: 'barcode = ?', whereArgs: [barcode]);
    return hasil.isNotEmpty ? hasil.first : null;
  }

  Future<List<String>> getDistinctValues(String column) async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT DISTINCT $column FROM barang WHERE $column != ""');
    return result.map((e) => e[column] as String).toList();
  }

  // --- LEVEL AKSES (YANG TADI SEMPAT TERHAPUS) ---
  Future<List<Map<String, dynamic>>> getSemuaLevel() async =>
      await (await instance.database)
          .query('level_akses', orderBy: 'nama_level ASC');
  Future<int> tambahLevel(Map<String, dynamic> data) async =>
      await (await instance.database).insert('level_akses', data);
  Future<int> updateLevel(int id, Map<String, dynamic> data) async =>
      await (await instance.database)
          .update('level_akses', data, where: 'id = ?', whereArgs: [id]);
  Future<int> hapusLevel(int id) async => await (await instance.database)
      .delete('level_akses', where: 'id = ?', whereArgs: [id]);

  // --- ABSENSI & CCTV DIGITAL ---
  Future<List<Map<String, dynamic>>> getAbsensiHariIni(String tanggal) async =>
      await (await instance.database).rawQuery(
          'SELECT absensi.*, karyawan.nama FROM absensi JOIN karyawan ON absensi.id_karyawan = karyawan.id WHERE absensi.tanggal = ? ORDER BY absensi.jam_masuk DESC',
          [tanggal]);
  Future<List<Map<String, dynamic>>> getLogAktivitas() async =>
      await (await instance.database)
          .query('log_aktivitas', orderBy: 'id DESC', limit: 100);
  Future<void> catatLog(String nama, String aktivitas) async =>
      await (await instance.database).insert(
          'log_aktivitas', {'nama_karyawan': nama, 'aktivitas': aktivitas});
  Future<Map<String, dynamic>?> cekAbsenHariIni(
      int idKaryawan, String tanggal) async {
    final hasil = await (await instance.database).query('absensi',
        where: 'id_karyawan = ? AND tanggal = ?',
        whereArgs: [idKaryawan, tanggal]);
    return hasil.isNotEmpty ? hasil.first : null;
  }

  Future<int> absenMasuk(Map<String, dynamic> data) async =>
      await (await instance.database).insert('absensi', data);
  Future<int> absenPulang(int idAbsen, Map<String, dynamic> data) async =>
      await (await instance.database)
          .update('absensi', data, where: 'id = ?', whereArgs: [idAbsen]);

  // --- PAYROLL & KASBON (FITUR BARU BOS!) ---
  Future<void> tambahKasbonKaryawan(int idKaryawan, double jumlahTambah) async {
    final db = await instance.database;
    await db.rawUpdate('UPDATE karyawan SET kasbon = kasbon + ? WHERE id = ?',
        [jumlahTambah, idKaryawan]);
  }

  Future<void> cairkanGaji(
      {required int idKaryawan,
      required String periode,
      required double gajiPokok,
      required double lembur,
      required double potonganKasbon,
      required double gajiBersih}) async {
    final db = await instance.database;

    // Simpan ke riwayat penggajian
    await db.insert('penggajian', {
      'id_karyawan': idKaryawan,
      'periode_bulan': periode,
      'gaji_pokok': gajiPokok,
      'bonus_lembur': lembur,
      'potongan_kasbon': potonganKasbon,
      'gaji_bersih': gajiBersih
    });

    // Lunasi/Kurangi hutang kasbon
    await db.rawUpdate('UPDATE karyawan SET kasbon = kasbon - ? WHERE id = ?',
        [potonganKasbon, idKaryawan]);

    // Terekam CCTV
    await catatLog('SISTEM PAYROLL',
        'Gaji periode $periode telah dicairkan untuk Karyawan ID: $idKaryawan');
  }
}
