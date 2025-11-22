//storage sementara buat data group
class GroupItem {
  final String name;
  final String image; // Path gambar (asset)
  final int members;
  final String category; // Kontrakan, Olahraga, dll.

  GroupItem({
    required this.name,
    this.image = 'assets/images/design1.png', // Default image
    this.members = 1,
    this.category = 'Lainnya',
  });
}

// INI LIST GLOBAL YANG AKAN DIAKSES SEMUA HALAMAN
List<GroupItem> globalGroupList = [
  GroupItem(name: 'DAP A17', members: 11, category: 'Kontrakan'),
  GroupItem(name: 'Badminton DAP A17', members: 9, category: 'Olahraga'),
  GroupItem(name: 'Rumah Angkatan', members: 112, category: 'Lainnya'),
];