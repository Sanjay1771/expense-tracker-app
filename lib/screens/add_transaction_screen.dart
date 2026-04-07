// Add Transaction screen — dark theme with slide-up animation
// UX: button below amount, expandable note for Bills/Shopping/Other, auto-nav home
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final VoidCallback? onTransactionAdded;

  const AddTransactionScreen({super.key, this.onTransactionAdded});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _categoryDescCtrl = TextEditingController(); // mini-note for detail categories
  final _fs = FirestoreService();
  final _auth = AuthService();

  TransactionType _type = TransactionType.expense;
  Category? _category;
  DateTime _date = DateTime.now();
  bool _saving = false;

  // Slide-up animation
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  /// Categories that show the expandable mini-note input
  static const _detailCategories = {'Bills', 'Shopping', 'Other'};

  @override
  void initState() {
    super.initState();
    _category = AppCategories.expenseCategories.first;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _categoryDescCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  /// Whether current category should show the expandable detail input
  bool get _showDetailInput =>
      _category != null && _detailCategories.contains(_category!.name);

  /// Hint text based on selected category
  String get _detailHint {
    switch (_category?.name) {
      case 'Bills':
        return 'e.g. Electricity Bill, Water Bill, Internet...';
      case 'Shopping':
        return 'e.g. Groceries, Clothes, Electronics...';
      case 'Other':
        return 'e.g. Gym membership, Gift for friend...';
      default:
        return 'Describe this transaction...';
    }
  }

  List<Category> get _categories => _type == TransactionType.expense
      ? AppCategories.expenseCategories
      : AppCategories.incomeCategories;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.neonBlue,
            surface: AppTheme.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  /// Save transaction then auto-navigate back to home
  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _category == null) return;
    setState(() => _saving = true);

    // Build the final note:
    // If a detail-category description was entered, use it as the primary note.
    // If the user also wrote a general note, combine them.
    String? finalNote;
    final hasDesc = _categoryDescCtrl.text.trim().isNotEmpty;
    final hasNote = _noteCtrl.text.trim().isNotEmpty;

    if (hasDesc && hasNote) {
      finalNote = '${_categoryDescCtrl.text.trim()} — ${_noteCtrl.text.trim()}';
    } else if (hasDesc) {
      finalNote = _categoryDescCtrl.text.trim();
    } else if (hasNote) {
      finalNote = _noteCtrl.text.trim();
    }

    final amount = double.parse(_amountCtrl.text);
    final categoryName = _category!.name;

    await _fs.addTransaction(TransactionModel(
      title: categoryName,
      amount: amount,
      category: categoryName,
      date: _date,
      note: finalNote,
      type: _type,
      userId: _auth.userId,
    ));

    if (mounted) {
      setState(() => _saving = false);

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.neonGreen, size: 20),
          const SizedBox(width: 10),
          Text('Transaction added!',
              style: GoogleFonts.poppins(color: Colors.white)),
        ]),
        backgroundColor: AppTheme.bgCard,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1200),
      ));

      // Notify parent to refresh data, then navigate back to home
      widget.onTransactionAdded?.call();

      // Small delay so user sees the snackbar, then auto-navigate home
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Add Transaction',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Type toggle ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(AppTheme.r12),
                      border: Border.all(
                        color: AppTheme.textMuted.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _toggle('Expense', Icons.arrow_upward_rounded,
                            _type == TransactionType.expense,
                            AppTheme.neonRed, () {
                          setState(() {
                            _type = TransactionType.expense;
                            _category =
                                AppCategories.expenseCategories.first;
                            _categoryDescCtrl.clear();
                          });
                        }),
                        _toggle('Income', Icons.arrow_downward_rounded,
                            _type == TransactionType.income,
                            AppTheme.neonGreen, () {
                          setState(() {
                            _type = TransactionType.income;
                            _category =
                                AppCategories.incomeCategories.first;
                            _categoryDescCtrl.clear();
                          });
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Amount ──────────────────────────────────
                  _label('Amount'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted.withValues(alpha: 0.3),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 8),
                        child: Text('₹',
                            style: GoogleFonts.poppins(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.neonBlue)),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter amount';
                      if (double.tryParse(v) == null ||
                          double.parse(v) <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Add Transaction button (below amount) ───
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.r16),
                        ),
                        elevation: 0,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.r16),
                          boxShadow: AppTheme.neonGlow(
                              AppTheme.neonBlue,
                              blur: 16),
                        ),
                        child: Center(
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                              : Text('Add Transaction',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Category ────────────────────────────────
                  _label('Category'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categories.map((c) {
                      final sel = _category?.name == c.name;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _category = c);
                          // Clear detail desc when switching to a non-detail category
                          if (!_detailCategories.contains(c.name)) {
                            _categoryDescCtrl.clear();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? c.color.withValues(alpha: 0.15)
                                : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? c.color
                                  : AppTheme.textMuted
                                      .withValues(alpha: 0.12),
                              width: sel ? 1.5 : 1,
                            ),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color:
                                          c.color.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c.icon,
                                  size: 16,
                                  color: sel
                                      ? c.color
                                      : AppTheme.textMuted),
                              const SizedBox(width: 6),
                              Text(c.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight:
                                        sel ? FontWeight.w600 : FontWeight.w400,
                                    color: sel
                                        ? c.color
                                        : AppTheme.textSecondary,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // ── Expandable detail input (Bills/Shopping/Other) ──
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showDetailInput
                        ? Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.bgCard,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.r12),
                                border: Border.all(
                                  color: (_category?.color ?? AppTheme.neonPurple)
                                      .withValues(alpha: 0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_category?.color ?? AppTheme.neonPurple)
                                        .withValues(alpha: 0.06),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.edit_note_rounded,
                                          color: (_category?.color ?? AppTheme.neonPurple)
                                              .withValues(alpha: 0.8),
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'What is this for?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _category?.color ?? AppTheme.neonPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _categoryDescCtrl,
                                    maxLines: 2,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _detailHint,
                                      hintStyle: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textMuted
                                            .withValues(alpha: 0.5),
                                      ),
                                      filled: true,
                                      fillColor: AppTheme.bgCardLight,
                                      contentPadding:
                                          const EdgeInsets.all(14),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // ── Date ────────────────────────────────────
                  _label('Date'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCardLight,
                        borderRadius: BorderRadius.circular(AppTheme.r12),
                        border: Border.all(
                          color: AppTheme.textMuted.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppTheme.neonBlue, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(_date),
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Note (kept as-is) ───────────────────────
                  _label('Note (optional)'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                        hintText: 'Write a note...'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, IconData icon, bool sel, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: sel ? color : AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight:
                        sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? color : AppTheme.textMuted,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary));
}
