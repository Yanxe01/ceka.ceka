import 'package:intl/intl.dart';
import 'reminder_service.dart'; // Import layanan teknis notifikasi

// --- Model Data (Contoh) ---
class Expense {
  final String expenseId;
  final String title;
  final DateTime paymentDeadline;
  final List<Member> members;

  Expense({required this.expenseId, required this.title, required this.paymentDeadline, required this.members});
}

class Member {
  final String memberId;
  final String memberName;
  final double amountDue;
  
  Member({required this.memberId, required this.memberName, required this.amountDue});
}
// ---------------------------

/// ExpenseManager atau ExpenseService
/// Bertanggung jawab untuk logika bisnis, termasuk kapan dan bagaimana
/// pengingat harus dipanggil.
class ExpenseManager {
  // Instance dari layanan teknis notifikasi
  final ReminderService _reminderService = ReminderService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  // Panggil fungsi ini setelah expense berhasil disimpan ke database.
  Future<void> scheduleRemindersForExpense(Expense expense) async {
    for (var member in expense.members) {
      // 1. BUAT KUNCI UNIK: Ini mencegah bentrokan notifikasi antar anggota.
      final String uniqueNotificationKey = '${expense.expenseId}_${member.memberId}'; 
      
      // 2. Buat pesan yang dipersonalisasi
      final String formattedAmount = _currencyFormat.format(member.amountDue);
      final String notificationTitle = '💰 Pengingat Pembayaran: ${expense.title}';
      final String notificationBody = 
        'Halo ${member.memberName}, mohon bayar bagian Anda ($formattedAmount) sebelum deadline ${DateFormat.yMd().format(expense.paymentDeadline)}.';
      
      // 3. Panggil ReminderService (Logika Teknis)
      await _reminderService.scheduleReminderForExpense(
        uniqueNotificationKey,
        expense.paymentDeadline,
        title: notificationTitle,
        body: notificationBody,
        payload: uniqueNotificationKey,
      );
    }
  }

  // Fungsi untuk membatalkan pengingat saat anggota sudah membayar
  Future<void> cancelMemberReminder(String expenseId, String memberId) async {
    final String uniqueNotificationKey = '${expenseId}_$memberId';
    await _reminderService.cancelReminderForExpense(uniqueNotificationKey);
  }
}