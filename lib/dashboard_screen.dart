import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'data_barang_screen.dart';
import 'kelola_karyawan_screen.dart';
import 'absensi_screen.dart';
import 'pengawasan_screen.dart';
import 'payroll_screen.dart'; // Manggil layar Penggajian

class DashboardScreen extends StatelessWidget {
  final int idKaryawan;
  final String nama;
  final String role;

  const DashboardScreen(
      {super.key,
      required this.idKaryawan,
      required this.nama,
      required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('WaroengKU - $role',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, $nama! 👋',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900])),
            const SizedBox(height: 5),
            Text('Jangan lupa Absen Masuk sebelum bekerja!',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(context, Icons.camera_front, 'Mesin Absensi',
                      Colors.teal),
                  if (role == 'BOS' || role == 'KASIR')
                    _buildMenuCard(context, Icons.point_of_sale, 'Kasir Utama',
                        Colors.green),
                  if (role == 'BOS' || role == 'LAPANGAN')
                    _buildMenuCard(context, Icons.qr_code_scanner, 'QR Estafet',
                        Colors.orange),
                  _buildMenuCard(
                      context, Icons.inventory, 'Data Barang', Colors.blue),
                  _buildMenuCard(
                      context, Icons.people, 'Data Pelanggan', Colors.purple),

                  // MENU DEWA KHUSUS BOS
                  if (role == 'BOS')
                    _buildMenuCard(context, Icons.security_rounded,
                        'CCTV & Absen', Colors.indigo),
                  if (role == 'BOS')
                    _buildMenuCard(context, Icons.account_balance_wallet,
                        'Auto-Payroll', Colors.teal), // TOMBOL BARU
                  if (role == 'BOS')
                    _buildMenuCard(context, Icons.manage_accounts,
                        'Kelola Karyawan', Colors.blueGrey),
                  if (role == 'BOS')
                    _buildMenuCard(context, Icons.bar_chart,
                        'Laporan Penjualan', Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, IconData icon, String title, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // Navigasi berdasarkan nama tombol
          if (title == 'Mesin Absensi') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AbsensiScreen(
                        idKaryawan: idKaryawan, namaKaryawan: nama)));
          } else if (title == 'Data Barang') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DataBarangScreen(role: role)));
          } else if (title == 'Kelola Karyawan') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => KelolaKaryawanScreen()));
          } else if (title == 'CCTV & Absen') {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => PengawasanScreen()));
          } else if (title == 'Auto-Payroll') {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => PayrollScreen()));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Sabar Bos, menu $title lagi diracik! 🛠️')));
          }
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Icon(icon, size: 45, color: color),
            ),
            const SizedBox(height: 15),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900])),
          ],
        ),
      ),
    );
  }
}
