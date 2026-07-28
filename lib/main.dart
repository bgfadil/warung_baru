import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- Import kamus kalender
import 'login_screen.dart';

void main() async {
  // Pemanasan wajib agar Flutter siap menyambung ke database lokal dan fitur lainnya
  WidgetsFlutterBinding.ensureInitialized();

  // Membuka kamus format tanggal Bahasa Indonesia (Wajib buat Mesin Absensi)
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaroengKU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}
