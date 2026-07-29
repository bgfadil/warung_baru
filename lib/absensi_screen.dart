import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class AbsensiScreen extends StatefulWidget {
  final int idKaryawan;
  final String namaKaryawan;

  const AbsensiScreen(
      {super.key, required this.idKaryawan, required this.namaKaryawan});

  @override
  _AbsensiScreenState createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  Map<String, dynamic>? dataAbsenHariIni;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cekStatusAbsen();
  }

  void _cekStatusAbsen() async {
    String tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = await DatabaseHelper.instance
        .cekAbsenHariIni(widget.idKaryawan, tanggalHariIni);
    setState(() {
      dataAbsenHariIni = data;
      isLoading = false;
    });
  }

  Future<void> _prosesAbsen(String tipe) async {
    // Mewajibkan jepret pakai kamera depan (selfie)
    final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 60);

    if (photo == null) return; // Batal absen kalau gak mau foto

    String tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String jamSekarang = DateFormat('HH:mm').format(DateTime.now());

    if (tipe == 'MASUK') {
      await DatabaseHelper.instance.absenMasuk({
        'id_karyawan': widget.idKaryawan,
        'tanggal': tanggalHariIni,
        'jam_masuk': jamSekarang,
        'foto_masuk': photo.path,
      });
      await DatabaseHelper.instance.catatLog(
          widget.namaKaryawan, 'Melakukan Absen MASUK pada $jamSekarang');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Absen Masuk Berhasil! Selamat Bekerja!'),
          backgroundColor: Colors.green));
    } else {
      await DatabaseHelper.instance.absenPulang(dataAbsenHariIni!['id'], {
        'jam_pulang': jamSekarang,
        'foto_pulang': photo.path,
      });
      await DatabaseHelper.instance.catatLog(
          widget.namaKaryawan, 'Melakukan Absen PULANG pada $jamSekarang');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Absen Pulang Berhasil! Hati-hati di jalan!'),
          backgroundColor: Colors.orange));
    }

    _cekStatusAbsen(); // Refresh layar
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool sudahMasuk = dataAbsenHariIni != null;
    bool sudahPulang = sudahMasuk && dataAbsenHariIni!['jam_pulang'] != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mesin Absensi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_front, size: 80, color: Colors.blue[800]),
              const SizedBox(height: 20),
              Text('Halo, ${widget.namaKaryawan}!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900])),
              const SizedBox(height: 10),
              Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                      .format(DateTime.now()),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),

              const SizedBox(height: 40),

              // LOGIKA STATUS TAMPILAN TOMBOL ABSEN
              if (!sudahMasuk) ...[
                const Text('Anda belum absen masuk hari ini.',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    icon: const Icon(Icons.login),
                    label: const Text('Jepret Selfie Absen MASUK',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () => _prosesAbsen('MASUK'),
                  ),
                )
              ] else if (sudahMasuk && !sudahPulang) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green[300]!)),
                  child: Column(
                    children: [
                      Text('Status: SEDANG BEKERJA',
                          style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('Jam Masuk: ${dataAbsenHariIni!['jam_masuk']}',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white),
                    icon: const Icon(Icons.logout),
                    label: const Text('Jepret Selfie Absen PULANG',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () => _prosesAbsen('PULANG'),
                  ),
                )
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[300]!)),
                  child: Column(
                    children: [
                      Icon(Icons.verified, color: Colors.blue[800], size: 50),
                      const SizedBox(height: 10),
                      Text('Absensi Selesai!',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900])),
                      const SizedBox(height: 10),
                      Text(
                          'Masuk: ${dataAbsenHariIni!['jam_masuk']} | Pulang: ${dataAbsenHariIni!['jam_pulang']}'),
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
