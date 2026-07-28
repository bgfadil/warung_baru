import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
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
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class DataBarangScreen extends StatefulWidget {
  final String role;
  const DataBarangScreen({Key? key, required this.role}) : super(key: key);

  @override
  _DataBarangScreenState createState() => _DataBarangScreenState();
}

class _DataBarangScreenState extends State<DataBarangScreen> {
  List<Map<String, dynamic>> _listBarang = [];

  List<String> _listKategori = [];
  List<String> _listProdusen = [];
  List<String> _listSupplier = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final data = await DatabaseHelper.instance.getSemuaBarang();
    final kat = await DatabaseHelper.instance.getDistinctValues('kategori');
    final prod = await DatabaseHelper.instance.getDistinctValues('produsen');
    final sup = await DatabaseHelper.instance.getDistinctValues('supplier');
    setState(() {
      _listBarang = data;
      _listKategori = kat;
      _listProdusen = prod;
      _listSupplier = sup;
    });
  }

  int _parseRupiah(String text) {
    String clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  String _formatRupiah(num value) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(value);
  }

  String _singkatBarcode(String barcode) {
    String clean = barcode.replaceAll(RegExp(r'[()]'), '');
    if (clean.length > 8) {
      return '${clean.substring(0, 3)}${clean.substring(clean.length - 5)}';
    }
    return clean;
  }

  Future<void> _scanDanTambahBarang() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        String barcodeHasil = result.rawContent;
        final cekBarang =
            await DatabaseHelper.instance.cariBarangByBarcode(barcodeHasil);
        if (!mounted) return;
        if (cekBarang != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Barang sudah ada di database!'),
              backgroundColor: Colors.red));
        } else {
          _tampilkanForm(barcode: barcodeHasil);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal kamera: $e'), backgroundColor: Colors.red));
    }
  }

  void _tampilkanForm(
      {required String barcode, Map<String, dynamic>? dataLama}) {
    TextEditingController namaCtrl =
        TextEditingController(text: dataLama?['nama_barang'] ?? '');
    TextEditingController modalCtrl = TextEditingController(
        text: dataLama != null ? _formatRupiah(dataLama['harga_modal']) : '');
    TextEditingController jualCtrl = TextEditingController(
        text: dataLama != null ? _formatRupiah(dataLama['harga_jual']) : '');
    TextEditingController stokCtrl = TextEditingController(
        text: dataLama != null ? dataLama['stok'].toString() : '');
    TextEditingController deskripsiCtrl =
        TextEditingController(text: dataLama?['deskripsi'] ?? '');
    TextEditingController notaCtrl =
        TextEditingController(text: dataLama?['no_nota'] ?? '');
    TextEditingController kategoriCtrl =
        TextEditingController(text: dataLama?['kategori'] ?? '');
    TextEditingController produsenCtrl =
        TextEditingController(text: dataLama?['produsen'] ?? '');
    TextEditingController supplierCtrl =
        TextEditingController(text: dataLama?['supplier'] ?? '');

    List<XFile> fotoPilihan = [];
    if (dataLama != null && dataLama['foto_produk'] != '[]') {
      List<dynamic> paths = jsonDecode(dataLama['foto_produk']);
      fotoPilihan = paths.map((p) => XFile(p.toString())).toList();
    }

    ScrollController _fotoScrollCtrl = ScrollController();
    int? selectedImageIndex;

    void _autoScrollKeUjung() {
      Future.delayed(Duration(milliseconds: 150), () {
        if (_fotoScrollCtrl.hasClients) {
          _fotoScrollCtrl.animateTo(_fotoScrollCtrl.position.maxScrollExtent,
              duration: Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(dataLama == null ? 'Tambah Barang' : 'Edit Barang',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue[900])),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 90,
                            child: fotoPilihan.isEmpty
                                ? Center(
                                    child: Text('Belum ada foto',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12)))
                                : ListView.builder(
                                    controller: _fotoScrollCtrl,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: fotoPilihan.length,
                                    itemBuilder: (ctx, i) {
                                      bool isSelected = selectedImageIndex == i;
                                      return GestureDetector(
                                        onLongPress: () {
                                          setStateDialog(() =>
                                              selectedImageIndex =
                                                  isSelected ? null : i);
                                        },
                                        onTap: () {
                                          if (selectedImageIndex != null) {
                                            setStateDialog(() =>
                                                selectedImageIndex =
                                                    isSelected ? null : i);
                                          }
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: isSelected
                                                ? Border.all(
                                                    color: Colors.red, width: 3)
                                                : Border.all(
                                                    color: Colors.transparent,
                                                    width: 3),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.file(
                                                File(fotoPilihan[i].path),
                                                width: 74,
                                                height: 84,
                                                fit: BoxFit.cover),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () async {
                                    final XFile? photo = await ImagePicker()
                                        .pickImage(
                                            source: ImageSource.camera,
                                            imageQuality: 70);
                                    if (photo != null) {
                                      setStateDialog(
                                          () => fotoPilihan.add(photo));
                                      _autoScrollKeUjung();
                                    }
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    margin:
                                        EdgeInsets.only(right: 4, bottom: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.blue[200]!)),
                                    child: Icon(Icons.camera_alt,
                                        color: Colors.blue[800], size: 20),
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final List<XFile> images =
                                        await ImagePicker()
                                            .pickMultiImage(imageQuality: 70);
                                    if (images.isNotEmpty) {
                                      setStateDialog(
                                          () => fotoPilihan.addAll(images));
                                      _autoScrollKeUjung();
                                    }
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    margin: EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.green[200]!)),
                                    child: Icon(Icons.photo_library,
                                        color: Colors.green[800], size: 20),
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: selectedImageIndex != null
                                  ? () {
                                      setStateDialog(() {
                                        fotoPilihan
                                            .removeAt(selectedImageIndex!);
                                        selectedImageIndex = null;
                                      });
                                    }
                                  : null,
                              child: Container(
                                width: 84,
                                height: 35,
                                decoration: BoxDecoration(
                                    color: selectedImageIndex != null
                                        ? Colors.red[50]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: selectedImageIndex != null
                                            ? Colors.red[200]!
                                            : Colors.grey[300]!)),
                                child: Icon(Icons.delete,
                                    color: selectedImageIndex != null
                                        ? Colors.red
                                        : Colors.grey[400],
                                    size: 20),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                    SizedBox(height: 20),
                    TextField(
                        decoration: InputDecoration(
                            labelText: 'Kode Barcode',
                            filled: true,
                            fillColor: Colors.grey[200]),
                        controller: TextEditingController(text: barcode),
                        enabled: false),
                    SizedBox(height: 10),
                    TextField(
                        controller: namaCtrl,
                        decoration: InputDecoration(
                            labelText: 'Nama Produk',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)))),
                    SizedBox(height: 10),
                    TextField(
                        controller: modalCtrl,
                        decoration: InputDecoration(
                            labelText: 'Harga Modal',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10))),
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()]),
                    SizedBox(height: 10),
                    TextField(
                        controller: jualCtrl,
                        decoration: InputDecoration(
                            labelText: 'Harga Jual',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10))),
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()]),
                    SizedBox(height: 10),
                    TextField(
                        controller: stokCtrl,
                        decoration: InputDecoration(
                            labelText: 'Stok Awal',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10))),
                        keyboardType: TextInputType.number),
                    SizedBox(height: 10),
                    TextField(
                        controller: deskripsiCtrl,
                        decoration: InputDecoration(
                            labelText: 'Deskripsi Produk',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10))),
                        maxLines: 2),
                    SizedBox(height: 10),
                    _buildSmartInput(
                        'Kategori / Rak', kategoriCtrl, _listKategori),
                    SizedBox(height: 10),
                    _buildSmartInput('Produsen', produsenCtrl, _listProdusen),
                    SizedBox(height: 10),
                    _buildSmartInput('Supplier', supplierCtrl, _listSupplier),
                    SizedBox(height: 10),
                    TextField(
                        controller: notaCtrl,
                        decoration: InputDecoration(
                            labelText: 'No Nota Supplier',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)))),
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
                  String jsonFoto =
                      jsonEncode(fotoPilihan.map((e) => e.path).toList());
                  Map<String, dynamic> dataKirim = {
                    'barcode': barcode,
                    'nama_barang': namaCtrl.text,
                    'harga_modal': _parseRupiah(modalCtrl.text),
                    'harga_jual': _parseRupiah(jualCtrl.text),
                    'stok': int.tryParse(stokCtrl.text) ?? 0,
                    'deskripsi': deskripsiCtrl.text,
                    'kategori': kategoriCtrl.text,
                    'produsen': produsenCtrl.text,
                    'supplier': supplierCtrl.text,
                    'no_nota': notaCtrl.text,
                    'foto_produk': jsonFoto,
                  };

                  if (dataLama == null) {
                    await DatabaseHelper.instance.tambahBarang(dataKirim);
                  } else {
                    await DatabaseHelper.instance
                        .updateBarang(dataLama['id'], dataKirim);
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  _refreshData();
                },
                child: Text('Simpan'),
              )
            ],
          );
        });
      },
    );
  }

  void _tampilkanDetailProduk(Map<String, dynamic> item, List<dynamic> fotos) {
    showDialog(
      context: context,
      builder: (context) {
        int _indexFotoSekarang = 0;
        return StatefulBuilder(builder: (context, setStateDetail) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fotos.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(
                            height: 250,
                            child: PageView.builder(
                              itemCount: fotos.length,
                              onPageChanged: (idx) => setStateDetail(
                                  () => _indexFotoSekarang = idx),
                              itemBuilder: (ctx, i) => ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(File(fotos[i]),
                                      fit: BoxFit.contain)),
                            ),
                          ),
                          SizedBox(height: 10),
                          if (fotos.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  fotos.length,
                                  (i) => Container(
                                        margin:
                                            EdgeInsets.symmetric(horizontal: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _indexFotoSekarang == i
                                              ? Colors.blue[800]
                                              : Colors.grey[300],
                                        ),
                                      )),
                            )
                        ],
                      )
                    else
                      Icon(Icons.image_not_supported,
                          size: 80, color: Colors.grey[300]),

                    SizedBox(height: 20),
                    Text(item['nama_barang'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900])),
                    SizedBox(height: 5),
                    Text(_formatRupiah(item['harga_jual']),
                        style: TextStyle(
                            fontSize: 26,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold)),
                    Divider(height: 30),

                    if (widget.role == 'BOS')
                      _buildDetailBaris(
                          'Modal', _formatRupiah(item['harga_modal'])),

                    _buildDetailBaris('Stok', item['stok'].toString()),
                    _buildDetailBaris('Kategori',
                        item['kategori'] == '' ? '-' : item['kategori']),
                    _buildDetailBaris('Produsen',
                        item['produsen'] == '' ? '-' : item['produsen']),

                    if (widget.role == 'BOS') ...[
                      _buildDetailBaris('Supplier',
                          item['supplier'] == '' ? '-' : item['supplier']),
                      _buildDetailBaris('No Nota',
                          item['no_nota'] == '' ? '-' : item['no_nota']),
                    ],

                    // KODE BC: Full untuk BOS, Pendek untuk selain BOS
                    _buildDetailBaris('Kode BC',
                        'BC${widget.role == 'BOS' ? item['barcode'] : _singkatBarcode(item['barcode'])}'),

                    if (item['deskripsi'] != '') ...[
                      SizedBox(height: 10),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Deskripsi:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700]))),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(item['deskripsi'],
                              style: TextStyle(color: Colors.grey[800]))),
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
        });
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
              width: 100,
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

  Widget _buildSmartInput(
      String label, TextEditingController ctrl, List<String> options) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue text) {
        if (text.text == '') return const Iterable<String>.empty();
        return options.where((String option) =>
            option.toLowerCase().contains(text.text.toLowerCase()));
      },
      onSelected: (String selection) => ctrl.text = selection,
      fieldViewBuilder: (context, txtCtrl, focusNode, onFieldSubmitted) {
        txtCtrl.text = ctrl.text;
        txtCtrl.addListener(() => ctrl.text = txtCtrl.text);
        return TextField(
            controller: txtCtrl,
            focusNode: focusNode,
            decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Gudang Data Barang',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _listBarang.isEmpty
          ? Center(
              child: Text('Gudang Kosong, Silakan Scan Barang',
                  style: TextStyle(fontSize: 16, color: Colors.grey)))
          : ListView.builder(
              itemCount: _listBarang.length,
              itemBuilder: (context, index) {
                final item = _listBarang[index];
                List<dynamic> fotos = jsonDecode(item['foto_produk'] ?? '[]');

                return Card(
                  elevation: 1,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _tampilkanDetailProduk(item, fotos),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              fotos.isNotEmpty
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(File(fotos[0]),
                                              width: 75,
                                              height: 75,
                                              fit: BoxFit.cover),
                                        ),
                                        if (fotos.length > 1)
                                          Positioned(
                                            bottom: 4,
                                            left: 0,
                                            right: 0,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: List.generate(
                                                  fotos.length,
                                                  (i) => Container(
                                                        margin: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 2),
                                                        width: 5,
                                                        height: 5,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Colors.white,
                                                            border: Border.all(
                                                                color: Colors
                                                                    .black45,
                                                                width: 0.5)),
                                                      )),
                                            ),
                                          )
                                      ],
                                    )
                                  : Container(
                                      width: 75,
                                      height: 75,
                                      decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Icon(Icons.image,
                                          color: Colors.grey[400], size: 30),
                                    ),
                              SizedBox(height: 8),
                              Text(_formatRupiah(item['harga_jual']),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Text(
                                      item['nama_barang'],
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                    if (widget.role == 'BOS')
                                      InkWell(
                                        onTap: () => _tampilkanForm(
                                            barcode: item['barcode'],
                                            dataLama: item),
                                        child: Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                              color: Colors.orange[50],
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          child: Icon(Icons.edit,
                                              color: Colors.orange[800],
                                              size: 18),
                                        ),
                                      )
                                  ],
                                ),
                                SizedBox(height: 6),

                                Text(
                                    widget.role == 'BOS'
                                        ? 'Modal: ${_formatRupiah(item['harga_modal'])} | Stok: ${item['stok']}'
                                        : 'Stok Tersedia: ${item['stok']}',
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 12)),

                                SizedBox(height: 2),
                                Text(
                                    item['kategori'] == ''
                                        ? '-'
                                        : item['kategori'],
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 12)),
                                SizedBox(height: 2),

                                // KODE BC: Full untuk BOS, Pendek untuk selain BOS
                                Text(
                                    'BC${widget.role == 'BOS' ? item['barcode'] : _singkatBarcode(item['barcode'])}',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 11)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanDanTambahBarang,
        icon: Icon(Icons.camera_alt),
        label: Text('Scan Barang Baru',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
    );
  }
}
