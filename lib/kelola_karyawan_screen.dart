import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    int value =
        int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String newText = formatter.format(value);
    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}

class KelolaKaryawanScreen extends StatefulWidget {
  @override
  _KelolaKaryawanScreenState createState() => _KelolaKaryawanScreenState();
}

class _KelolaKaryawanScreenState extends State<KelolaKaryawanScreen> {
  List<Map<String, dynamic>> _listKaryawan = [];
  List<Map<String, dynamic>> _listLevel = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final db = await DatabaseHelper.instance.database;
    final dataKaryawan = await db.query('karyawan',
        where: 'role != ?', whereArgs: ['BOS'], orderBy: 'nama ASC');
    final dataLevel = await DatabaseHelper.instance.getSemuaLevel();

    setState(() {
      _listKaryawan = dataKaryawan;
      _listLevel = dataLevel;
    });
  }

  String _formatRupiah(num value) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(value);
  }

  int _parseRupiah(String text) {
    String clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  void _tampilkanFormKaryawan({Map<String, dynamic>? dataLama}) {
    TextEditingController namaCtrl =
        TextEditingController(text: dataLama?['nama'] ?? '');
    TextEditingController pinCtrl =
        TextEditingController(text: dataLama?['pin'] ?? '');
    TextEditingController alamatCtrl =
        TextEditingController(text: dataLama?['alamat'] ?? '');
    TextEditingController gajiCtrl = TextEditingController(
        text: dataLama != null && dataLama['gaji'] != 0.0
            ? _formatRupiah(dataLama['gaji'])
            : '');
    TextEditingController tglMulaiCtrl =
        TextEditingController(text: dataLama?['tgl_mulai'] ?? '');

    String rolePilihan = dataLama?['role'] ?? 'KASIR';
    String shiftPilihan =
        (dataLama?['shift'] == null || dataLama?['shift'] == '')
            ? 'Pagi'
            : dataLama!['shift'];
    String levelPilihan = dataLama?['nama_level'] ??
        (_listLevel.isNotEmpty ? _listLevel[0]['nama_level'] : 'Level 1');

    XFile? fotoProfil;
    XFile? fotoKtp;

    if (dataLama != null) {
      if (dataLama['foto_profil'] != "")
        fotoProfil = XFile(dataLama['foto_profil']);
      if (dataLama['foto_ktp'] != "") fotoKtp = XFile(dataLama['foto_ktp']);
    }

    Future<void> _pilihTanggal(
        BuildContext context, StateSetter setStateDialog) async {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        setStateDialog(() {
          tglMulaiCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
        });
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
                dataLama == null ? 'Tambah Karyawan' : 'Edit Data Karyawan',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue[900])),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final photo = await ImagePicker().pickImage(
                                source: ImageSource.camera, imageQuality: 50);
                            if (photo != null)
                              setStateDialog(() => fotoProfil = photo);
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.blue[50],
                                backgroundImage: fotoProfil != null
                                    ? FileImage(File(fotoProfil!.path))
                                    : null,
                                child: fotoProfil == null
                                    ? Icon(Icons.person_add_alt_1,
                                        size: 30, color: Colors.blue[800])
                                    : null,
                              ),
                              SizedBox(height: 5),
                              Text('Foto Profil',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700]))
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final photo = await ImagePicker().pickImage(
                                source: ImageSource.camera, imageQuality: 50);
                            if (photo != null)
                              setStateDialog(() => fotoKtp = photo);
                          },
                          child: Column(
                            children: [
                              Container(
                                width: 90,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  image: fotoKtp != null
                                      ? DecorationImage(
                                          image: FileImage(File(fotoKtp!.path)),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: fotoKtp == null
                                    ? Icon(Icons.credit_card,
                                        color: Colors.green[800])
                                    : null,
                              ),
                              SizedBox(height: 5),
                              Text('Foto KTP',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700]))
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextField(
                        controller: namaCtrl,
                        decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)))),
                    SizedBox(height: 10),
                    TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                          labelText: 'PIN Login (6 Digit)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[300]!)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: levelPilihan,
                          icon: Icon(Icons.admin_panel_settings,
                              color: Colors.blue[800]),
                          items: _listLevel.map((level) {
                            return DropdownMenuItem<String>(
                              value: level['nama_level'],
                              child: Text('Hak Akses: ${level['nama_level']}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900])),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setStateDialog(() => levelPilihan = val);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: rolePilihan,
                      decoration: InputDecoration(
                          labelText: 'Posisi / Jabatan',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                      items: ['KASIR', 'LAPANGAN']
                          .map((val) =>
                              DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setStateDialog(() => rolePilihan = val);
                      },
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: shiftPilihan,
                      decoration: InputDecoration(
                          labelText: 'Jadwal / Shift',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                      items: ['Pagi', 'Siang', 'Sore', 'Malam', 'Fleksibel']
                          .map((val) =>
                              DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setStateDialog(() => shiftPilihan = val);
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: tglMulaiCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                          labelText: 'Tanggal Mulai',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          suffixIcon: Icon(Icons.calendar_month,
                              color: Colors.blue[800])),
                      onTap: () => _pilihTanggal(context, setStateDialog),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: gajiCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'Gaji Pokok',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10))),
                      inputFormatters: [CurrencyInputFormatter()],
                    ),
                    SizedBox(height: 10),
                    TextField(
                        controller: alamatCtrl,
                        decoration: InputDecoration(
                            labelText: 'Alamat Lengkap',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10))),
                        maxLines: 2),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  if (namaCtrl.text.isEmpty || pinCtrl.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Nama & PIN 6 Digit wajib diisi!'),
                        backgroundColor: Colors.orange));
                    return;
                  }

                  final db = await DatabaseHelper.instance.database;
                  if (dataLama == null || dataLama['pin'] != pinCtrl.text) {
                    final cekPin = await db.query('karyawan',
                        where: 'pin = ?', whereArgs: [pinCtrl.text]);
                    if (cekPin.isNotEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Gagal! PIN sudah dipakai orang lain.'),
                          backgroundColor: Colors.red));
                      return;
                    }
                  }

                  Map<String, dynamic> dataKirim = {
                    'nama': namaCtrl.text,
                    'pin': pinCtrl.text,
                    'role': rolePilihan,
                    'status_aktif': dataLama?['status_aktif'] ?? 1,
                    'foto_profil': fotoProfil?.path ?? "",
                    'foto_ktp': fotoKtp?.path ?? "",
                    'alamat': alamatCtrl.text,
                    'gaji': _parseRupiah(gajiCtrl.text),
                    'tgl_mulai': tglMulaiCtrl.text,
                    'shift': shiftPilihan,
                    'nama_level': levelPilihan,
                  };

                  if (dataLama == null) {
                    await DatabaseHelper.instance.tambahKaryawan(dataKirim);
                    // Catat ke CCTV Digital
                    await DatabaseHelper.instance.catatLog(
                        'BOS', 'Mendaftarkan karyawan baru: ${namaCtrl.text}');
                  } else {
                    await DatabaseHelper.instance
                        .updateKaryawan(dataLama['id'], dataKirim);
                    // Catat ke CCTV Digital
                    await DatabaseHelper.instance.catatLog(
                        'BOS', 'Mengedit data karyawan: ${namaCtrl.text}');
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Data Karyawan Tersimpan!'),
                      backgroundColor: Colors.green));
                },
                child: Text('Simpan'),
              )
            ],
          );
        });
      },
    );
  }

  void _tampilkanDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: (item['foto_profil'] != null &&
                            item['foto_profil'] != "")
                        ? FileImage(File(item['foto_profil']))
                        : null,
                    child: (item['foto_profil'] == null ||
                            item['foto_profil'] == "")
                        ? Icon(Icons.person, size: 50, color: Colors.blue[800])
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(item['nama'],
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900])),
                  Text(item['role'],
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold)),
                  Divider(height: 30),
                  _buildDetailBaris('PIN Login', item['pin']),
                  _buildDetailBaris('Status',
                      item['status_aktif'] == 1 ? 'Aktif Bekerja' : 'Nonaktif'),
                  _buildDetailBaris('Tgl Masuk',
                      item['tgl_mulai'] == "" ? '-' : item['tgl_mulai']),
                  _buildDetailBaris('Jadwal Shift',
                      item['shift'] == "" ? '-' : item['shift']),
                  _buildDetailBaris('Gaji Pokok', _formatRupiah(item['gaji'])),
                  _buildDetailBaris(
                      'Hak Akses', item['nama_level'] ?? 'Level 1'),
                  SizedBox(height: 10),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Alamat Lengkap:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700]))),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item['alamat'] == "" ? '-' : item['alamat'],
                          style: TextStyle(color: Colors.grey[800]))),
                  if (item['foto_ktp'] != null && item['foto_ktp'] != "") ...[
                    SizedBox(height: 20),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Dokumen KTP:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700]))),
                    SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(item['foto_ktp']),
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover),
                    ),
                  ],
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        child: Text('Tutup Detail')),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailBaris(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Text(':', style: TextStyle(color: Colors.grey[600])),
          SizedBox(width: 10),
          Expanded(
              child: Text(nilai,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[800]))),
        ],
      ),
    );
  }

  void _ubahStatusKaryawan(int id, int statusSekarang, String nama) async {
    final db = await DatabaseHelper.instance.database;
    int statusBaru = statusSekarang == 1 ? 0 : 1;
    await db.update('karyawan', {'status_aktif': statusBaru},
        where: 'id = ?', whereArgs: [id]);

    // Catat ke CCTV Digital
    String aktivitas = statusBaru == 1
        ? 'Membuka blokir akun: $nama'
        : 'Memblokir akun: $nama';
    await DatabaseHelper.instance.catatLog('BOS', aktivitas);

    _refreshData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            statusBaru == 1 ? '$nama diaktifkan!' : 'Akses $nama diblokir!'),
        backgroundColor: statusBaru == 1 ? Colors.green : Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Data Kepegawaian',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.shield, color: Colors.orange),
            tooltip: 'Atur Level Akses',
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ManajemenLevelScreen()));
              _refreshData();
            },
          )
        ],
      ),
      body: _listKaryawan.isEmpty
          ? Center(
              child: Text('Belum ada karyawan yang didaftarkan.',
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _listKaryawan.length,
              itemBuilder: (context, index) {
                final item = _listKaryawan[index];
                bool isAktif = item['status_aktif'] == 1;

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _tampilkanDetail(item),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                isAktif ? Colors.blue[100] : Colors.grey[300],
                            backgroundImage: (item['foto_profil'] != null &&
                                    item['foto_profil'] != "")
                                ? FileImage(File(item['foto_profil']))
                                : null,
                            child: (item['foto_profil'] == null ||
                                    item['foto_profil'] == "")
                                ? Icon(
                                    item['role'] == 'KASIR'
                                        ? Icons.point_of_sale
                                        : Icons.qr_code_scanner,
                                    color: isAktif
                                        ? Colors.blue[800]
                                        : Colors.grey[600])
                                : null,
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['nama'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isAktif
                                            ? Colors.black
                                            : Colors.grey)),
                                SizedBox(height: 4),
                                // --- LOGIKA PERGANTIAN TULISAN LEVEL KE AKSES DIBLOKIR ---
                                Row(
                                  children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isAktif
                                                ? Colors.green
                                                : Colors.red)),
                                    SizedBox(width: 5),
                                    Text(isAktif ? 'Aktif' : 'Nonaktif',
                                        style: TextStyle(
                                            color: isAktif
                                                ? Colors.green[700]
                                                : Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 5),
                                    Text(
                                        isAktif
                                            ? '• ${item['nama_level'] ?? "Level 1"}'
                                            : '• Akses diblokir',
                                        style: TextStyle(
                                            color: isAktif
                                                ? Colors.grey[600]
                                                : Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: isAktif
                                                ? FontStyle.normal
                                                : FontStyle
                                                    .italic // Jadi miring kalau diblokir
                                            )),
                                  ],
                                )
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () =>
                                    _tampilkanFormKaryawan(dataLama: item),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.edit,
                                      color: Colors.orange[800], size: 18),
                                ),
                              ),
                              SizedBox(height: 8),
                              InkWell(
                                onTap: () => _ubahStatusKaryawan(item['id'],
                                    item['status_aktif'], item['nama']),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: isAktif
                                          ? Colors.grey[200]
                                          : Colors.red[50],
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.block,
                                      color: isAktif
                                          ? Colors.grey[500]
                                          : Colors.red,
                                      size: 18),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilkanFormKaryawan(),
        icon: Icon(Icons.person_add),
        label: Text('Tambah Pasukan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
    );
  }
}

// =========================================================================
// HALAMAN KHUSUS PENGATURAN LEVEL AKSES
// =========================================================================
class ManajemenLevelScreen extends StatefulWidget {
  @override
  _ManajemenLevelScreenState createState() => _ManajemenLevelScreenState();
}

class _ManajemenLevelScreenState extends State<ManajemenLevelScreen> {
  List<Map<String, dynamic>> _listLevel = [];

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  void _loadLevel() async {
    final data = await DatabaseHelper.instance.getSemuaLevel();
    setState(() => _listLevel = data);
  }

  void _formLevel({Map<String, dynamic>? levelLama}) {
    TextEditingController namaLevelCtrl =
        TextEditingController(text: levelLama?['nama_level'] ?? '');
    List<String> aksesTerpilih = [];
    if (levelLama != null && levelLama['daftar_akses'] != null) {
      aksesTerpilih = List<String>.from(jsonDecode(levelLama['daftar_akses']));
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            Widget _buildCeklis(String kode, String label, IconData icon) {
              bool isChecked = aksesTerpilih.contains(kode);
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: Colors.orange[800],
                controlAffinity: ListTileControlAffinity.leading,
                title: Row(
                  children: [
                    Icon(icon, size: 18, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[800]))),
                  ],
                ),
                value: isChecked,
                onChanged: (bool? val) {
                  setStateDialog(() {
                    if (val == true)
                      aksesTerpilih.add(kode);
                    else
                      aksesTerpilih.remove(kode);
                  });
                },
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(levelLama == null ? 'Buat Level Baru' : 'Edit Level',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.orange[900])),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                          controller: namaLevelCtrl,
                          decoration: InputDecoration(
                              labelText: 'Nama Level (Misal: Kasir Senior)',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)))),
                      SizedBox(height: 15),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Tentukan Hak Akses:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]))),
                      Divider(),
                      _buildCeklis('input_barang', 'Boleh Tambah/Edit Barang',
                          Icons.inventory),
                      _buildCeklis('hapus_barang', 'Boleh Hapus Data Barang',
                          Icons.delete_forever),
                      _buildCeklis('input_pelanggan',
                          'Boleh Tambah/Edit Pelanggan', Icons.person_add),
                      _buildCeklis('hapus_pelanggan', 'Boleh Hapus Pelanggan',
                          Icons.person_remove),
                      _buildCeklis('kasbon', 'Boleh Kelola Kasbon',
                          Icons.account_balance_wallet),
                      _buildCeklis('lihat_laporan',
                          'Boleh Lihat Laporan Penjualan', Icons.bar_chart),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Batal', style: TextStyle(color: Colors.red))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    if (namaLevelCtrl.text.isEmpty) return;

                    Map<String, dynamic> dataKirim = {
                      'nama_level': namaLevelCtrl.text,
                      'daftar_akses': jsonEncode(aksesTerpilih)
                    };

                    if (levelLama == null) {
                      await DatabaseHelper.instance.tambahLevel(dataKirim);
                    } else {
                      await DatabaseHelper.instance
                          .updateLevel(levelLama['id'], dataKirim);
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadLevel();
                  },
                  child: Text('Simpan'),
                )
              ],
            );
          });
        });
  }

  void _hapusLevel(int id) async {
    await DatabaseHelper.instance.hapusLevel(id);
    _loadLevel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Pusat Kendali Level',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: _listLevel.length,
        itemBuilder: (context, index) {
          final level = _listLevel[index];
          List<String> akses =
              List<String>.from(jsonDecode(level['daftar_akses']));

          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ExpansionTile(
              leading: Icon(Icons.security, color: Colors.orange[800]),
              title: Text(level['nama_level'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('${akses.length} Izin Diberikan',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: akses.isEmpty
                            ? [
                                Text('Tidak ada akses khusus',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontStyle: FontStyle.italic))
                              ]
                            : akses
                                .map((a) => Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.orange[200]!)),
                                      child: Text(
                                          a.replaceAll('_', ' ').toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange[900],
                                              fontWeight: FontWeight.bold)),
                                    ))
                                .toList(),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                              onPressed: () => _hapusLevel(level['id']),
                              icon: Icon(Icons.delete,
                                  color: Colors.red, size: 18),
                              label: Text('Hapus',
                                  style: TextStyle(color: Colors.red))),
                          ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[800],
                                  foregroundColor: Colors.white),
                              onPressed: () => _formLevel(levelLama: level),
                              icon: Icon(Icons.edit, size: 18),
                              label: Text('Edit'))
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formLevel(),
        icon: Icon(Icons.add_moderator),
        label: Text('Buat Level Baru',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
    );
  }
}
