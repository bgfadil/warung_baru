# RENCANA 1: Input Barang Nota Supplier

Fitur supplier bawa nota + dus-dusan

### Tahap 1 - Input Nota (Supplier Datang)
- [ ] Input No Nota, Tgl, Foto Nota
- [ ] Pilih Supplier
- [ ] Input list barang (satuan Dus/Lusin/Kg)
- [ ] Simpan sebagai DRAFT (stok belum nambah)

### Tahap 2 - Verifikasi Bongkar (Scan 1x)
- [ ] Scan barcode DUS 1x aja
- [ ] App auto pecah: 1 Dus Indomie = 40 Pcs
- [ ] Hitung modal otomatis: modal_dus / isi
- [ ] Input jumlah fisik asli
- [ ] Stok auto nambah dalam Pcs

### Tahap 3 - Hutang & Retur
- [ ] Nota SELESAI -> Hutang ke supplier jadi
- [ ] Kalo ada rusak/kurang -> Buat Retur
- [ ] Hutang otomatis kepotong retur

### Database
- [ ] Table konversi_satuan (dus, lusin, kg ke pcs)
- [ ] Table nota_supplier + nota_item
- [ ] Table hutang_supplier
