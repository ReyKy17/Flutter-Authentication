import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//1
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
//

class _HomeScreenState extends State<HomeScreen> {
//2
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _kontakController = TextEditingController();
//

  @override
  void dispose() {
    _namaBarangController.dispose();
    _lokasiController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

//3
  Future<void> _simpanLaporan() async {
    final user = FirebaseAuth.instance.currentUser;
    final namaBarang = _namaBarangController.text.trim();
    final lokasiDitemukan = _lokasiController.text.trim();
    final kontakPelapor = _kontakController.text.trim();

    if (user == null ||
        namaBarang.isEmpty ||
        lokasiDitemukan.isEmpty ||
        kontakPelapor.isEmpty) {
      return;
    }

    await _firestore.collection('user_data').add({
      'namaBarang': namaBarang,
      'lokasiDitemukan': lokasiDitemukan,
      'kontakPelapor': kontakPelapor,
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'userEmail': user.email ?? '',
    });

    _namaBarangController.clear();
    _lokasiController.clear();
    _kontakController.clear();
  }
//
//8
  Future<void> _hapusLaporan(String docId) async {
    await _firestore.collection('user_data').doc(docId).delete();
  }
//
//9
  Future<void> _confirmDelete(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus data?'),
        content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _hapusLaporan(docId);
    }
  }
//

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Barang Hilang'),
        actions: [
//10
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
//
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GREETING
            Text(
              'Selamat datang, ${user?.email ?? 'Pengguna'}!',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 20),

            Text(
              'Isi data laporan barang hilang di bawah ini.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 12),
//4
            TextField(
              controller: _namaBarangController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _lokasiController,
              decoration: const InputDecoration(
                labelText: 'Lokasi Ditemukan',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _kontakController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Kontak Pelapor',
                border: OutlineInputBorder(),
              ),
            ),
//
            const SizedBox(height: 10),
//5
            ElevatedButton(
              onPressed: _simpanLaporan,
              child: const Text('Simpan Data'),
            ),
//
            const SizedBox(height: 20),

            const Text(
              'Data Tersimpan:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // LIST DATA
            Expanded(
//6
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('user_data')
                    .where('userId', isEqualTo: user?.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
//
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Belum ada data.'),
                    );
                  }

                  final docs = snapshot.data!.docs;
//7
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      final namaBarang = data['namaBarang'] ?? '-';
                      final lokasiDitemukan =
                          data['lokasiDitemukan'] ?? '-';
                      final kontakPelapor =
                          data['kontakPelapor'] ?? '-';
                      final createdAt =
                          (data['createdAt'] as Timestamp?)?.toDate().toString() ??
                              'Tidak ada waktu';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(namaBarang.toString()),
                          subtitle: Text(
                            'Lokasi: $lokasiDitemukan\n'
                            'Kontak: $kontakPelapor\n'
                            'Pelapor: ${data['userEmail'] ?? '-'} • $createdAt',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Hapus data',
                            onPressed: () => _confirmDelete(docs[index].id),
                          ),
                        ),
                      );
                    },
                  );
//
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}