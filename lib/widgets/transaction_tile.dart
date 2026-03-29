// Dark-themed transaction tile with note display
// Tap shows full details bottom sheet with delete option
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  /// The display title: use note if available, otherwise category name
  String get _displayTitle {
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      return transaction.note!;
    }
    return transaction.category;
  }

  /// Show full transaction details bottom sheet with delete option
  void _showDetailSheet(BuildContext context) {
    final category = transaction.categoryData;
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? AppTheme.neonGreen : AppTheme.neonRed;
    final prefix = isIncome ? '+' : '-';
    final typeLabel = isIncome ? 'Income' : 'Expense';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header: icon + category + type badge
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: category.color.withValues(alpha: 0.15),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(category.icon,
                        color: category.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(transaction.category,
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: amountColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(typeLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: amountColor)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$prefix₹${transaction.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: amountColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Detail rows
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(AppTheme.r16),
                  border: Border.all(
                    color: AppTheme.textMuted.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    _detailRow(
                      Icons.calendar_today_rounded,
                      'Date',
                      DateFormat('EEEE, MMM dd, yyyy')
                          .format(transaction.date),
                      AppTheme.neonBlue,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(
                        height: 1,
                        color:
                            AppTheme.textMuted.withValues(alpha: 0.08),
                      ),
                    ),
                    _detailRow(
                      Icons.category_rounded,
                      'Category',
                      transaction.category,
                      category.color,
                    ),
                    // Note row (only if note exists)
                    if (transaction.note != null &&
                        transaction.note!.isNotEmpty) ...[
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: AppTheme.textMuted
                              .withValues(alpha: 0.08),
                        ),
                      ),
                      _detailRow(
                        Icons.sticky_note_2_rounded,
                        'Note',
                        transaction.note!,
                        AppTheme.neonPurple,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons: Close + Delete
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: BorderSide(
                            color: AppTheme.textMuted
                                .withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Close',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          // Show delete confirmation dialog
                          _confirmDelete(context);
                        },
                        icon:
                            const Icon(Icons.delete_rounded, size: 18),
                        label: Text('Delete',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Confirmation dialog before deleting
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.r16)),
        title: Text('Delete Transaction',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        content: Text(
            'Are you sure you want to delete this transaction? This cannot be undone.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Delete',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// A single detail row inside the details card
  Widget _detailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppTheme.textMuted)),
            const SizedBox(height: 1),
            SizedBox(
              width: 220,
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = transaction.categoryData;
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? AppTheme.neonGreen : AppTheme.neonRed;
    final prefix = isIncome ? '+' : '-';
    final hasNote =
        transaction.note != null && transaction.note!.isNotEmpty;

    // Tap to show full details (with delete option inside)
    return GestureDetector(
      onTap: () => _showDetailSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.r16),
          border: Border.all(
            color: AppTheme.textMuted.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Category icon with glow
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child:
                  Icon(category.icon, color: category.color, size: 22),
            ),
            const SizedBox(width: 14),
            // Title (note or category) + subtitle (date + category)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary: note if available, otherwise category
                  Text(
                    _displayTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Subtitle: category name (if note is used as title) + date
                  Row(
                    children: [
                      if (hasNote) ...[
                        Text(
                          transaction.category,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: category.color.withValues(alpha: 0.8),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 5),
                          child: Text('·',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppTheme.textMuted)),
                        ),
                      ],
                      Text(
                        DateFormat('MMM dd, yyyy')
                            .format(transaction.date),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '$prefix₹${transaction.amount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
