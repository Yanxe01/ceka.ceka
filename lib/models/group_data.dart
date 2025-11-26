//storage sementara buat data group
class GroupItem {
  final String name;
  final String image; // Path gambar (asset)
  // PERUBAHAN: Mengubah dari jumlah (int) menjadi daftar nama (List<String>)
  final List<String> members; 
  final String category; // Kontrakan, Olahraga, dll.

  GroupItem({
    required this.name,
    this.image = 'assets/images/design1.png', // Default image
    required this.members, // Required now
    this.category = 'Lainnya',
  });

  // Getter untuk mendapatkan jumlah member (agar kode lama tidak error parah)
  int get memberCount => members.length;
}

// INI LIST GLOBAL YANG AKAN DIAKSES SEMUA HALAMAN
// PERUBAHAN: Update dummy data dengan nama-nama anggota
List<GroupItem> globalGroupList = [
  GroupItem(
    name: 'DAP A17', 
    members: ['Ian', 'Azizah', 'Evita', 'Ara', 'Vinan', 'Jijah'], 
    category: 'Kontrakan'
  ),
  GroupItem(
    name: 'Badminton DAP A17', 
    members: ['Ian', 'Irgi', 'Deryl', 'Rafqy'], 
    category: 'Olahraga'
  ),
  GroupItem(
    name: 'Rumah Angkatan', 
    members: ['Banyak Orang'], 
    category: 'Lainnya'
  ),
];