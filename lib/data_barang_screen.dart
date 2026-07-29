import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class DataBarangScreen extends StatefulWidget {
  final String role;
  const DataBarangScreen({super.key, required this.role});
  @override
  _DataBarangScreenState createState() => _DataBarangScreenState();
}

class _DataBarangScreenState extends State<DataBarangScreen> {
  List<Map<String, dynamic>> _listBarang = [];
  List<Map<String, dynamic>> _barangFiltered = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  final Set<int> _selectedBarang = {};

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final data = await DatabaseHelper.instance.getSemuaBarang();
    setState(() {
      _listBarang = data;
      _barangFiltered = List.from(data);
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final q = query.toLowerCase().trim();
      if (q.isEmpty) {
        setState(() => _barangFiltered = List.from(_listBarang));
        return;
      }
      setState(() {
        _barangFiltered = _listBarang.where((item) {
          final nama = (item['nama_barang'] ?? '').toString().toLowerCase();
          final kategori = (item['kategori'] ?? '').toString().toLowerCase();
          final barcode = (item['barcode'] ?? '').toString().toLowerCase();
          return nama.contains(q) ||
              kategori.contains(q) ||
              barcode.contains(q);
        }).toList();
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedBarang.contains(id)) {
        _selectedBarang.remove(id);
      } else {
        _selectedBarang.add(id);
      }
    });
  }

  void _clearSelection() => setState(() => _selectedBarang.clear());
  Future<void> _hapusBarang(int id) async {
    await DatabaseHelper.instance.hapusBarang(id);
    if (!mounted) return;
    _refreshData();
  }

  Future<void> _hapusSelectedBarang() async {
    if (_selectedBarang.isEmpty) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Hapus Banyak Barang'),
              content: Text('Hapus ${_selectedBarang.length} barang terpilih?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal')),
                ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Hapus'))
              ],
            ));
    if (confirmed != true) return;
    for (final id in _selectedBarang.toList()) {
      await DatabaseHelper.instance.hapusBarang(id);
    }
    if (!mounted) return;
    _clearSelection();
    _refreshData();
  }

  String _formatRupiah(num value) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(value);

  Future<void> _scanDanTambahBarang() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        final existing = await DatabaseHelper.instance
            .cariBarangByBarcode(result.rawContent);
        if (existing != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Barang sudah ada'), backgroundColor: Colors.red));
          return;
        }
        _tampilkanForm(barcode: result.rawContent);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Scan gagal: $e'), backgroundColor: Colors.red));
    }
  }

  // INI YANG SOLID 8 KOLOM BOS - JANGAN DIHAPUS LAGI
  void _tampilkanForm(
      {required String barcode, Map<String, dynamic>? dataLama}) {
    final namaCtrl =
        TextEditingController(text: dataLama?['nama_barang'] ?? '');
    final barcodeCtrl =
        TextEditingController(text: dataLama?['barcode'] ?? barcode);
    final jualCtrl = TextEditingController(
        text:
            dataLama != null ? (dataLama['harga_jual']?.toString() ?? '') : '');
    final modalCtrl = TextEditingController(
        text: dataLama != null
            ? (dataLama['harga_modal']?.toString() ?? '')
            : '');
    final stokCtrl = TextEditingController(
        text: dataLama != null ? (dataLama['stok']?.toString() ?? '') : '');
    final kategoriCtrl =
        TextEditingController(text: dataLama?['kategori'] ?? '');
    final produsenCtrl =
        TextEditingController(text: dataLama?['produsen'] ?? '');
    final supplierCtrl =
        TextEditingController(text: dataLama?['supplier'] ?? '');
    final noNotaCtrl = TextEditingController(text: dataLama?['no_nota'] ?? '');
    final deskripsiCtrl =
        TextEditingController(text: dataLama?['deskripsi'] ?? '');
    List<String> fotoList = dataLama != null
        ? (jsonDecode(dataLama['foto_produk'] ?? '[]') as List).cast<String>()
        : [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dataLama == null ? 'Tambah Barang' : 'Edit Barang'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: barcodeCtrl,
                decoration: const InputDecoration(labelText: 'Barcode')),
            const SizedBox(height: 8),
            TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Barang *')),
            const SizedBox(height: 8),
            TextField(
                controller: jualCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Jual')),
            const SizedBox(height: 8),
            TextField(
                controller: modalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Modal')),
            const SizedBox(height: 8),
            TextField(
                controller: stokCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok')),
            const SizedBox(height: 8),
            TextField(
                controller: kategoriCtrl,
                decoration: const InputDecoration(labelText: 'Kategori')),
            const SizedBox(height: 8),
            TextField(
                controller: produsenCtrl,
                decoration: const InputDecoration(labelText: 'Produsen')),
            const SizedBox(height: 8),
            TextField(
                controller: supplierCtrl,
                decoration: const InputDecoration(labelText: 'Supplier')),
            const SizedBox(height: 8),
            TextField(
                controller: noNotaCtrl,
                decoration: const InputDecoration(labelText: 'No Nota')),
            const SizedBox(height: 8),
            TextField(
                controller: deskripsiCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Deskripsi')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
              onPressed: () async {
                final data = {
                  'barcode': barcodeCtrl.text,
                  'nama_barang': namaCtrl.text,
                  'harga_jual': int.tryParse(
                          jualCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                      0,
                  'harga_modal': int.tryParse(
                          modalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                      0,
                  'stok': int.tryParse(stokCtrl.text) ?? 0,
                  'deskripsi': deskripsiCtrl.text,
                  'kategori': kategoriCtrl.text,
                  'produsen': produsenCtrl.text,
                  'supplier': supplierCtrl.text,
                  'no_nota': noNotaCtrl.text,
                  'foto_produk': jsonEncode(fotoList)
                };
                if (dataLama == null) {
                  await DatabaseHelper.instance.tambahBarang(data);
                } else {
                  await DatabaseHelper.instance
                      .updateBarang(dataLama['id'], data);
                }
                if (!mounted) return;
                Navigator.pop(ctx);
                _refreshData();
              },
              child: const Text('Simpan'))
        ],
      ),
    );
  }

  void _tampilkanDetailProduk(Map<String, dynamic> item, List<dynamic> fotos) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(item['nama_barang'] ?? '-'),
                content: Text(_formatRupiah(item['harga_jual'] ?? 0)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
          title: widget.role == 'BOS' && _selectedBarang.isNotEmpty
              ? Text('${_selectedBarang.length} terpilih')
              : const Text('Gudang Data Barang'),
          backgroundColor: Colors.blue[800]),
      body: Column(children: [
        Container(
            margin: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Cari nama/kategori/barcode',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))))),
        Expanded(
            child: _barangFiltered.isEmpty
                ? Center(
                    child: Text(_listBarang.isEmpty
                        ? 'Gudang Kosong'
                        : 'Barang tidak ditemukan'))
                : ListView.builder(
                    itemCount: _barangFiltered.length,
                    itemBuilder: (context, i) {
                      final item = _barangFiltered[i];
                      final fotos =
                          (jsonDecode(item['foto_produk'] ?? '[]') as List)
                              .cast<String>();
                      final isSelected = _selectedBarang.contains(item['id']);
                      return Stack(children: [
                        Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                  ? BorderSide(
                                      color: Colors.blue.shade700, width: 2)
                                  : BorderSide.none),
                          color: isSelected ? Colors.blue[50] : null,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onLongPress: widget.role == 'BOS'
                                ? () => _toggleSelection(item['id'])
                                : null,
                            onTap: widget.role == 'BOS' &&
                                    _selectedBarang.isNotEmpty
                                ? () => _toggleSelection(item['id'])
                                : () => _tampilkanDetailProduk(item, fotos),
                            child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(children: [
                                        fotos.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.file(
                                                    File(fotos[0]),
                                                    width: 75,
                                                    height: 75,
                                                    fit: BoxFit.cover))
                                            : Container(
                                                width: 75,
                                                height: 75,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image)),
                                        const SizedBox(height: 8),
                                        Text(
                                            _formatRupiah(
                                                item['harga_jual'] ?? 0),
                                            style: TextStyle(
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.bold))
                                      ]),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(item['nama_barang'] ?? '-',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue[900])),
                                            const SizedBox(height: 8),
                                            Text(item['kategori'] ?? '-',
                                                style: TextStyle(
                                                    color: Colors.grey[700]))
                                          ])),
                                      if (widget.role == 'BOS')
                                        Column(children: [
                                          InkWell(
                                              onTap: () => _tampilkanForm(
                                                  barcode:
                                                      item['barcode'] ?? '',
                                                  dataLama: item),
                                              child: Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                      color: Colors.orange[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                  child: Icon(Icons.edit,
                                                      color:
                                                          Colors.orange[800]))),
                                          const SizedBox(height: 8),
                                          if (_selectedBarang.isEmpty)
                                            InkWell(
                                                onTap: () async {
                                                  final c = await showDialog<
                                                          bool>(
                                                      context: context,
                                                      builder: (ctx) =>
                                                          AlertDialog(
                                                              title: const Text(
                                                                  'Hapus Barang'),
                                                              content: const Text(
                                                                  'Hapus barang ini?'),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            ctx,
                                                                            false),
                                                                    child: const Text(
                                                                        'Batal')),
                                                                ElevatedButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                            ctx,
                                                                            true),
                                                                    style: ElevatedButton.styleFrom(
                                                                        backgroundColor:
                                                                            Colors
                                                                                .red),
                                                                    child: const Text(
                                                                        'Hapus'))
                                                              ]));
                                                  if (c == true) {
                                                    await _hapusBarang(
                                                        item['id']);
                                                  }
                                                },
                                                child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                        color: Colors.red[50],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8)),
                                                    child: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red)))
                                        ])
                                    ])),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.check_circle,
                                      color: Colors.blue, size: 18)))
                      ]);
                    }))
      ]),
      floatingActionButton: widget.role == 'BOS' && _selectedBarang.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                FloatingActionButton(
                    onPressed: _clearSelection,
                    backgroundColor: Colors.grey[400],
                    child: const Icon(Icons.close, color: Colors.blueAccent)),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                    onPressed: _hapusSelectedBarang,
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.blueAccent),
                    label: const Text('Hapus',
                        style: TextStyle(color: Colors.blueAccent)),
                    backgroundColor: Colors.red[700])
              ]))
          : FloatingActionButton.extended(
              onPressed: _scanDanTambahBarang,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Barang Baru'),
              backgroundColor: Colors.orange[700]),
    );
  }
}
