import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class PengawasanScreen extends StatefulWidget {
  @override
  _PengawasanScreenState createState() => _PengawasanScreenState();
}

class _PengawasanScreenState extends State<PengawasanScreen> {
  List<Map<String, dynamic>> _listAbsen = [];
  List<Map<String, dynamic>> _listLog = [];
  bool isLoading = true;
  String tglHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final absen = await DatabaseHelper.instance.getAbsensiHariIni(tglHariIni);
    final log = await DatabaseHelper.instance.getLogAktivitas();

    setState(() {
      _listAbsen = absen;
      _listLog = log;
      isLoading = false;
    });
  }

  // Jendela Pop-up untuk intip foto selfie karyawan
  void _lihatFotoSelfie(String tipe, String? path, String nama) {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Waduh, fotonya tidak ditemukan!'),
          backgroundColor: Colors.red));
      return;
    }
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Selfie $tipe - $nama',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900])),
              content: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(File(path),
                    fit: BoxFit.cover, width: double.infinity, height: 350),
              ),
              actions: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Tutup'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text('Ruang Pengawasan',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.indigo[800],
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.indigo[200],
            indicatorColor: Colors.orange,
            indicatorWeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.camera_front), text: 'Absensi Hari Ini'),
              Tab(icon: Icon(Icons.security), text: 'CCTV Digital'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ==========================================
            // TAB 1: ABSENSI HARI INI
            // ==========================================
            _listAbsen.isEmpty
                ? Center(
                    child: Text('Belum ada karyawan yang absen hari ini.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: _listAbsen.length,
                    itemBuilder: (context, index) {
                      final absen = _listAbsen[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: Colors.indigo[800]),
                                  SizedBox(width: 8),
                                  Text(absen['nama'],
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87)),
                                ],
                              ),
                              Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // Info Absen Masuk
                                  Column(
                                    children: [
                                      Text('Jam Masuk',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                      Text(absen['jam_masuk'] ?? '-',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green)),
                                      SizedBox(height: 5),
                                      OutlinedButton.icon(
                                          onPressed: () => _lihatFotoSelfie(
                                              'Masuk',
                                              absen['foto_masuk'],
                                              absen['nama']),
                                          icon:
                                              Icon(Icons.visibility, size: 16),
                                          label: Text('Lihat',
                                              style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green))
                                    ],
                                  ),
                                  Container(
                                      width: 1,
                                      height: 60,
                                      color: Colors.grey[300]),
                                  // Info Absen Pulang
                                  Column(
                                    children: [
                                      Text('Jam Pulang',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                      Text(absen['jam_pulang'] ?? '--:--',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: absen['jam_pulang'] != null
                                                  ? Colors.orange
                                                  : Colors.grey)),
                                      SizedBox(height: 5),
                                      OutlinedButton.icon(
                                          onPressed: absen['jam_pulang'] != null
                                              ? () => _lihatFotoSelfie(
                                                  'Pulang',
                                                  absen['foto_pulang'],
                                                  absen['nama'])
                                              : null,
                                          icon:
                                              Icon(Icons.visibility, size: 16),
                                          label: Text('Lihat',
                                              style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.orange))
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            // ==========================================
            // TAB 2: CCTV DIGITAL (LOG AKTIVITAS)
            // ==========================================
            _listLog.isEmpty
                ? Center(
                    child: Text('CCTV belum merekam aktivitas apapun.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: _listLog.length,
                    itemBuilder: (context, index) {
                      final log = _listLog[index];
                      return Card(
                        elevation: 1,
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo[50],
                            child: Icon(Icons.history_toggle_off,
                                color: Colors.indigo[800]),
                          ),
                          title: Text(log['aktivitas'],
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text('Oleh: ${log['nama_karyawan']}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700])),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
