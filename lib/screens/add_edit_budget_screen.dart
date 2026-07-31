import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import 'package:intl/intl.dart';

class AddEditBudgetScreen extends StatefulWidget {
  final BudgetModel? budget;
  const AddEditBudgetScreen({super.key, this.budget});

  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  final List<String> _categories = [
    'Food', 'Shopping', 'Medicine', 'Transport', 'Entertainment', 'Bills', 'General', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _amountCtrl.text = widget.budget!.budgetAmount.toStringAsFixed(0);
      _categoryCtrl.text = widget.budget!.category;
      _selectedMonth = widget.budget!.month;
      _selectedYear = widget.budget!.year;
    } else {
      _categoryCtrl.text = _categories.first;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountCtrl.text.trim());
      
      final budget = BudgetModel(
        id: widget.budget?.id,
        userId: user.id,
        category: _categoryCtrl.text.trim(),
        budgetAmount: amount,
        spentAmount: widget.budget?.spentAmount ?? 0,
        remainingAmount: widget.budget?.remainingAmount ?? amount,
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (widget.budget == null) {
        await BudgetService().addBudget(budget);
      } else {
        await BudgetService().updateBudget(budget);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.budget != null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Budget' : 'Create Budget'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(_categoryCtrl.text) ? _categoryCtrl.text : _categories.first,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: isEdit ? null : (val) {
                    if (val != null) _categoryCtrl.text = val;
                  }, // Disallow changing category when editing to simplify logic
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Budget Amount',
                    prefixIcon: Icon(Icons.currency_rupee_rounded, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Required';
                    final amt = double.tryParse(val.trim());
                    if (amt == null || amt <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        ),
                        items: List.generate(12, (index) {
                          final date = DateTime(2000, index + 1);
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(DateFormat('MMM').format(date)),
                          );
                        }),
                        onChanged: isEdit ? null : (val) {
                          if (val != null) setState(() => _selectedMonth = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        ),
                        items: List.generate(5, (index) {
                          final year = DateTime.now().year - 2 + index;
                          return DropdownMenuItem(value: year, child: Text(year.toString()));
                        }),
                        onChanged: isEdit ? null : (val) {
                          if (val != null) setState(() => _selectedYear = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _saveBudget,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
