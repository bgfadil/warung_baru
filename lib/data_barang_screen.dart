import 'package:flutter/material.dart';

class DataBarangScreen extends StatefulWidget {
  final String? role;
  const DataBarangScreen({super.key, this.role});
  @override
  State<DataBarangScreen> createState() => _DataBarangScreenState();
}

class _DataBarangScreenState extends State<DataBarangScreen> {
  bool _showRadial = false;
  final _search = TextEditingController();
  List<Map<String, dynamic>> _all = [
    {
      'nama_barang': 'Beras Pandan - 50kg',
      'barcode': 'BRG-00123',
      'stok': 12,
      'harga_jual': '145.000',
      'kategori': 'sak'
    },
    {
      'nama_barang': 'Minyak Goreng 1L',
      'barcode': 'BRG-00189',
      'stok': 30,
      'harga_jual': '18.500',
      'kategori': 'botol'
    },
    {
      'nama_barang': 'Gula Pasir - 1kg',
      'barcode': 'BRG-00302',
      'stok': 8,
      'harga_jual': '14.000',
      'kategori': 'kg'
    }
  ];
  List<Map<String, dynamic>> _filtered = [];
  @override
  void initState() {
    super.initState();
    _filtered = List.from(_all);
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() => _filtered = _all
          .where((b) => b['nama_barang'].toString().toLowerCase().contains(q))
          .toList());
    });
  }

  void _toggle() => setState(() => _showRadial = !_showRadial);
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      body: Stack(children: [
        Column(children: [
          Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Row(children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back)),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Gudang Data Barang ${widget.role ?? "BOS"}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800))),
                Icon(Icons.search),
                SizedBox(width: 8),
                Icon(Icons.notifications)
              ])),
          Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                          hintText: 'Cari barang... | Barcode, nama, SKU',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search))))),
          Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Color(0xFFDCE8FF),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Barang: ${_all.length} item',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              'Stok rendah: ${_all.where((e) => (e['stok'] ?? 0) < 10).length} item')
                        ]),
                    Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('Terupdate hari ini 09:30',
                            style: TextStyle(fontSize: 11)))
                  ])),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Daftar Barang',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Lihat semua >', style: TextStyle(color: Colors.blue))
                  ])),
          SizedBox(height: 8),
          Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 120),
                  itemCount: _filtered.length,
                  itemBuilder: (c, i) {
                    final b = _filtered[i];
                    final int stok = (b['stok'] as int?) ?? 0;
                    final low = stok < 10;
                    return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                            leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    color: [
                                      Color(0xFFC8E6C9),
                                      Color(0xFFFFE082),
                                      Color(0xFFF8BBD0)
                                    ][i % 3],
                                    borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.inventory_2)),
                            title: Text(b['nama_barang'].toString(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SKU: ${b['barcode']}',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  Row(children: [
                                    Icon(
                                        low
                                            ? Icons.warning_amber_rounded
                                            : Icons.check_circle,
                                        size: 16,
                                        color:
                                            low ? Colors.orange : Colors.green),
                                    SizedBox(width: 4),
                                    Text('Stok: $stok',
                                        style: TextStyle(
                                            color: low
                                                ? Colors.orange
                                                : Colors.green,
                                            fontSize: 12))
                                  ]),
                                  Text(
                                      'Rp ${b['harga_jual']} /${b['kategori']}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12))
                                ]),
                            trailing: Icon(Icons.more_horiz)));
                  }))
        ]),
        if (_showRadial)
          Positioned.fill(
              child: GestureDetector(
                  onTap: _toggle,
                  child: Container(color: Colors.black.withOpacity(0.15)))),
        // V6 = 5mm dari X biru (X ada di bottom ~35, jadi 5mm = ~20px gap)
        if (_showRadial)
          Positioned(
              bottom: 92,
              left: w / 2 - 26,
              child: _Btn(
                  icon: Icons.assignment,
                  label: 'Input Nota',
                  color: Colors.blue,
                  onTap: _toggle)),
        if (_showRadial)
          Positioned(
              bottom: 72,
              left: w / 2 - 26 - 62,
              child: _Btn(
                  icon: Icons.photo_camera,
                  label: 'Scan Eceran',
                  color: Colors.orange,
                  onTap: _toggle)),
        if (_showRadial)
          Positioned(
              bottom: 72,
              left: w / 2 - 26 + 62,
              child: _Btn(
                  icon: Icons.inventory_2,
                  label: 'Verifikasi',
                  color: Colors.green,
                  onTap: _toggle)),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: Color(0xFF2563EB),
          child: Icon(_showRadial ? Icons.close : Icons.add,
              color: Colors.white, size: 32)),
      bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
              height: 60,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.home, color: Colors.blue),
                      Text('Beranda',
                          style: TextStyle(fontSize: 10, color: Colors.blue))
                    ]),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inventory_2_outlined),
                      Text('Inventori', style: TextStyle(fontSize: 10))
                    ]),
                    SizedBox(width: 40),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bar_chart),
                      Text('Analitik', style: TextStyle(fontSize: 10))
                    ]),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_outline),
                      Text('Profil', style: TextStyle(fontSize: 10))
                    ])
                  ]))),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext c) {
    return Column(children: [
      Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.35), blurRadius: 5)
              ]),
          child: Icon(icon, color: Colors.white, size: 22)),
      SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700))
    ]);
  }
}
