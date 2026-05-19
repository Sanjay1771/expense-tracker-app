import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_db_service.dart';
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
  final _categoryDescCtrl = TextEditingController();
  final _db = SupabaseDbService();
  final _auth = AuthService();

  TransactionType _type = TransactionType.expense;
  Category? _category;
  DateTime _date = DateTime.now();
  bool _saving = false;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  static const _detailCategories = {'Bills', 'Shopping', 'Other'};

  @override
  void initState() {
    super.initState();
    _category = AppCategories.expenseCategories.first;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
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

  bool get _showDetailInput =>
      _category != null && _detailCategories.contains(_category!.name);

  String get _detailHint {
    switch (_category?.name) {
      case 'Bills':
        return 'e.g. Electricity, Water, Internet...';
      case 'Shopping':
        return 'e.g. Groceries, Clothes...';
      case 'Other':
        return 'e.g. Gym, Gift...';
      default:
        return 'Describe...';
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
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _category == null) return;
    setState(() => _saving = true);

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

    try {
      await _db.addTransaction(TransactionModel(
        title: categoryName,
        amount: amount,
        category: categoryName,
        date: _date,
        note: finalNote,
        type: _type,
        userId: _auth.userId,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.tertiary, size: 20),
              const SizedBox(width: 10),
              Text('Transaction added!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
            ]),
            backgroundColor: Theme.of(context).cardTheme.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        widget.onTransactionAdded?.call();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg, style: const TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_upward_rounded),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_downward_rounded),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<TransactionType> newSelection) {
                        setState(() {
                          _type = newSelection.first;
                          _category = _categories.first;
                          _categoryDescCtrl.clear();
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return _type == TransactionType.income
                                  ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2)
                                  : Theme.of(context).colorScheme.error.withValues(alpha: 0.2);
                            }
                            return null;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return _type == TransactionType.income ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.error;
                            }
                            return Theme.of(context).colorScheme.onSurface;
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Amount', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: _type == TransactionType.income ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.error,
                        ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 20, right: 8),
                        child: Text('₹',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                )),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter amount';
                      if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Category', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _categories.map((c) {
                      final isSelected = _category == c;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _category = c;
                          _categoryDescCtrl.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? c.color.withValues(alpha: 0.2) : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(AppTheme.r16),
                            border: Border.all(
                              color: isSelected ? c.color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c.icon, color: isSelected ? c.color : Theme.of(context).colorScheme.onSurface, size: 20),
                              const SizedBox(width: 8),
                              Text(c.name,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isSelected ? c.color : Theme.of(context).colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_showDetailInput) ...[
                    const SizedBox(height: 24),
                    Text('Detail', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _categoryDescCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: _detailHint,
                        prefixIcon: const Icon(Icons.short_text_rounded),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required for this category' : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(AppTheme.r16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(AppTheme.r16),
                                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(_date),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Optional Note', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add a note...',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _type == TransactionType.income ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.error,
                      ),
                      child: _saving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
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
}
