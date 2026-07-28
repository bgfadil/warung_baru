import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

// Formatter Rupiah untuk Inputan
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

class PayrollScreen extends StatefulWidget {
  @override
  _PayrollScreenState createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  List<Map<String, dynamic>> _listKaryawan = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final db = await DatabaseHelper.instance.database;
    // Jangan masukkan BOS di list penggajian
    final data = await db.query('karyawan',
        where: 'role != ?', whereArgs: ['BOS'], orderBy: 'nama ASC');
    setState(() {
      _listKaryawan = data;
      isLoading = false;
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

  // --- POPUP TAMBAH KASBON ---
  void _tambahKasbon(int idKaryawan, String namaKaryawan) {
    TextEditingController nominalCtrl = TextEditingController();

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: Text('Catat Kasbon Baru',
                  style: TextStyle(
                      color: Colors.orange[900], fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Karyawan: $namaKaryawan',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 15),
                  TextField(
                    controller: nominalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                        labelText: 'Nominal Kasbon',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: Icon(Icons.money, color: Colors.orange)),
                  ),
                ],
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
                    double nominal = _parseRupiah(nominalCtrl.text).toDouble();
                    if (nominal <= 0) return;

                    await DatabaseHelper.instance
                        .tambahKasbonKaryawan(idKaryawan, nominal);
                    await DatabaseHelper.instance.catatLog('BOS',
                        'Menambahkan kasbon Rp $nominal untuk $namaKaryawan');

                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Kasbon $namaKaryawan berhasil dicatat!'),
                        backgroundColor: Colors.green));
                  },
                  child: Text('Simpan'),
                )
              ],
            ));
  }

  // --- POPUP HITUNG & CAIRKAN GAJI ---
  void _hitungGaji(Map<String, dynamic> karyawan) {
    double gajiPokok = karyawan['gaji'] ?? 0.0;
    double kasbonAktif = karyawan['kasbon'] ?? 0.0;

    // Default lembur 0, bisa diedit Bos secara manual jika ada tambahan
    TextEditingController lemburCtrl = TextEditingController(text: 'Rp 0');
    // Kasbon yang mau dipotong (Otomatis terisi full kasbon, tapi Bos bisa kurangi kalau nyicil)
    TextEditingController potongKasbonCtrl =
        TextEditingController(text: _formatRupiah(kasbonAktif));

    String periodeBulan =
        DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            double hitungBersih() {
              double lembur = _parseRupiah(lemburCtrl.text).toDouble();
              double potong = _parseRupiah(potongKasbonCtrl.text).toDouble();
              return (gajiPokok + lembur) - potong;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Slip Gaji - $periodeBulan',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal[900])),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(karyawan['nama'],
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(karyawan['role'],
                          style: TextStyle(color: Colors.grey[600])),
                      Divider(height: 30, thickness: 1.5),

                      // Rincian Hitungan
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Gaji Pokok:'),
                            Text(_formatRupiah(gajiPokok),
                                style: TextStyle(fontWeight: FontWeight.bold))
                          ]),
                      SizedBox(height: 15),
                      TextField(
                        controller: lemburCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        decoration: InputDecoration(
                            labelText: 'Tambahan Lembur/Bonus (+)',
                            labelStyle: TextStyle(color: Colors.green),
                            border: OutlineInputBorder(),
                            isDense: true),
                        onChanged: (val) =>
                            setStateDialog(() {}), // Refresh tampilan total
                      ),
                      SizedBox(height: 15),

                      if (kasbonAktif > 0) ...[
                        Text(
                            'Sisa Hutang Kasbon: ${_formatRupiah(kasbonAktif)}',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        TextField(
                          controller: potongKasbonCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: InputDecoration(
                              labelText: 'Potongan Kasbon (-)',
                              labelStyle: TextStyle(color: Colors.red),
                              border: OutlineInputBorder(),
                              isDense: true),
                          onChanged: (val) => setStateDialog(() {}),
                        ),
                        SizedBox(height: 15),
                      ],

                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal[300]!)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('GAJI BERSIH:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[900])),
                            Text(_formatRupiah(hitungBersih()),
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[900])),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Batal', style: TextStyle(color: Colors.red))),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      foregroundColor: Colors.white),
                  icon: Icon(Icons.print, size: 18),
                  label: Text('Cairkan Gaji'),
                  onPressed: () async {
                    double gajiBersihFinal = hitungBersih();
                    double potonganFinal =
                        _parseRupiah(potongKasbonCtrl.text).toDouble();
                    double lemburFinal =
                        _parseRupiah(lemburCtrl.text).toDouble();

                    // Cek jangan sampai potongan lebih besar dari kasbon aslinya
                    if (potonganFinal > kasbonAktif) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('Error: Potongan melebihi total kasbon!'),
                          backgroundColor: Colors.red));
                      return;
                    }

                    await DatabaseHelper.instance.cairkanGaji(
                        idKaryawan: karyawan['id'],
                        periode: periodeBulan,
                        gajiPokok: gajiPokok,
                        lembur: lemburFinal,
                        potonganKasbon: potonganFinal,
                        gajiBersih: gajiBersihFinal);

                    if (!mounted) return;
                    Navigator.pop(context);
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Gaji Berhasil Dicairkan & Kasbon Terpotong!'),
                        backgroundColor: Colors.green));
                  },
                )
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Auto-Payroll & Kasbon',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: _listKaryawan.isEmpty
          ? Center(
              child: Text('Belum ada karyawan untuk digaji.',
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _listKaryawan.length,
              itemBuilder: (context, index) {
                final item = _listKaryawan[index];
                double gaji = item['gaji'] ?? 0.0;
                double kasbon = item['kasbon'] ?? 0.0;
                bool adaKasbon = kasbon > 0;

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal[100],
                              child:
                                  Icon(Icons.person, color: Colors.teal[800]),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nama'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text('Gaji Pokok: ${_formatRupiah(gaji)}',
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Total Kasbon',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                                Text(_formatRupiah(kasbon),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: adaKasbon
                                            ? Colors.red
                                            : Colors.green)),
                              ],
                            )
                          ],
                        ),
                        Divider(height: 25),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange[800],
                                    side:
                                        BorderSide(color: Colors.orange[800]!)),
                                onPressed: () =>
                                    _tambahKasbon(item['id'], item['nama']),
                                icon: Icon(Icons.add_card, size: 18),
                                label: Text('Catat Kasbon'),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[800],
                                    foregroundColor: Colors.white),
                                onPressed: () => _hitungGaji(item),
                                icon: Icon(Icons.calculate, size: 18),
                                label: Text('Hitung Gaji'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
