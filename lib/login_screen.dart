import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String pinInput = "";
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _pinController = TextEditingController();

  void _onKeyboardTyping(String val) {
    setState(() => pinInput = val);
    if (pinInput.length == 6) {
      _focusNode.unfocus();
      _prosesLogin();
    }
  }

  void _tekanTombol(String angka) {
    if (pinInput.length < 6) {
      setState(() {
        pinInput += angka;
        _pinController.text = pinInput;
      });
    }
    if (pinInput.length == 6) _prosesLogin();
  }

  void _hapusAngka() {
    setState(() {
      if (pinInput.isNotEmpty) {
        pinInput = pinInput.substring(0, pinInput.length - 1);
        _pinController.text = pinInput;
      }
    });
  }

  void _prosesLogin() async {
    if (pinInput.isEmpty) return;

    final user = await DatabaseHelper.instance.cekLogin(pinInput);
    if (!mounted) return;

    if (user != null) {
      int idKaryawan = user['id']; // Ambil ID buat Absensi
      String role = user['role'];
      String nama = user['nama'];

      // CATAT KE CCTV DIGITAL!
      await DatabaseHelper.instance
          .catatLog(nama, 'Berhasil Login ke Aplikasi');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Selamat datang, $nama!'),
          backgroundColor: Colors.green));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => DashboardScreen(
                idKaryawan: idKaryawan, nama: nama, role: role)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PIN Salah atau Akun Diblokir!'),
          backgroundColor: Colors.red));
      setState(() {
        pinInput = "";
        _pinController.clear();
      });
    }
  }

  Widget _buildNumpadButton(String angka) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () => _tekanTombol(angka),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(angka,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Opacity(
                opacity: 0,
                child: TextField(
                    controller: _pinController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.visiblePassword,
                    maxLength: 6,
                    onChanged: _onKeyboardTyping)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, size: 80, color: Colors.blue[800]),
                SizedBox(height: 10),
                Text('WAROENGKU',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800])),
                SizedBox(height: 30),
                Text('Masukkan PIN Anda',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < pinInput.length
                              ? Colors.blue[800]
                              : Colors.grey[300]),
                    );
                  }),
                ),
                SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Row(children: [
                        _buildNumpadButton('1'),
                        _buildNumpadButton('2'),
                        _buildNumpadButton('3')
                      ]),
                      Row(children: [
                        _buildNumpadButton('4'),
                        _buildNumpadButton('5'),
                        _buildNumpadButton('6')
                      ]),
                      Row(children: [
                        _buildNumpadButton('7'),
                        _buildNumpadButton('8'),
                        _buildNumpadButton('9')
                      ]),
                      Row(
                        children: [
                          Expanded(
                              child: IconButton(
                                  icon: Icon(Icons.keyboard,
                                      size: 32, color: Colors.blue[900]),
                                  onPressed: () => _focusNode.requestFocus())),
                          _buildNumpadButton('0'),
                          Expanded(
                              child: IconButton(
                                  icon: Icon(Icons.backspace,
                                      size: 28, color: Colors.blue[900]),
                                  onPressed: _hapusAngka)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
