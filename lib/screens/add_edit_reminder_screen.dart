import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder_model.dart';
import '../services/app_reminder_service.dart';


class AddEditReminderScreen extends StatefulWidget {
  final ReminderModel? reminder;

  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();
  bool _isOthersSelected = false;
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  RepeatType _repeatType = RepeatType.none;

  final _reminderService = AppReminderService();
  bool _isLoading = false;

  final List<String> _categories = [
    'Bills', 'EB (Electricity Bill)', 'Gas', 'Salary', 'EMI', 'Subscription', 'Insurance', 'Medicine', 'General', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleCtrl.text = widget.reminder!.title;
      _amountCtrl.text = widget.reminder!.amount?.toStringAsFixed(0) ?? '';
      _noteCtrl.text = widget.reminder!.note ?? '';
      _selectedDate = widget.reminder!.date;
      _selectedTime = widget.reminder!.time;
      _repeatType = widget.reminder!.repeatType;

      final savedCategory = widget.reminder!.category;
      if (_categories.contains(savedCategory) && savedCategory != 'Others') {
        _categoryCtrl.text = savedCategory;
        _isOthersSelected = false;
      } else {
        _categoryCtrl.text = 'Others';
        _customCategoryCtrl.text = savedCategory;
        _isOthersSelected = true;
      }
    } else {
      _categoryCtrl.text = _categories.first;
      _isOthersSelected = false;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _noteCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isLoading = true);

    double? amount;
    if (_amountCtrl.text.trim().isNotEmpty) {
      amount = double.tryParse(_amountCtrl.text.trim());
    }

    final categoryToSave = _isOthersSelected 
        ? _customCategoryCtrl.text.trim() 
        : _categoryCtrl.text.trim();

    final reminder = ReminderModel(
      id: widget.reminder?.id,
      userId: user.id,
      title: _titleCtrl.text.trim(),
      amount: amount,
      category: categoryToSave,
      note: _noteCtrl.text.trim(),
      date: _selectedDate,
      time: _selectedTime,
      repeatType: _repeatType,
      notificationId: widget.reminder?.notificationId ?? 0,
      isEnabled: widget.reminder?.isEnabled ?? true,
      createdAt: widget.reminder?.createdAt,
    );

    await _reminderService.saveReminder(reminder);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reminder != null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Reminder' : 'Add Reminder'),
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
                _buildTextField(_titleCtrl, 'Reminder Title', Icons.title, required: true),
                const SizedBox(height: 16),
                _buildTextField(_amountCtrl, 'Amount (Optional)', Icons.currency_rupee_rounded, isNumber: true),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                if (_isOthersSelected) ...[
                  const SizedBox(height: 16),
                  _buildCustomCategoryField(),
                ],
                const SizedBox(height: 16),
                _buildTextField(_noteCtrl, 'Note (Optional)', Icons.notes_rounded),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerCard(
                        'Date',
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        Icons.calendar_today_rounded,
                        _pickDate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPickerCard(
                        'Time',
                        _selectedTime.format(context),
                        Icons.access_time_rounded,
                        _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildRepeatDropdown(),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _saveReminder,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      ),
      validator: (val) {
        if (required && (val == null || val.trim().isEmpty)) {
          return 'Please enter a $label';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _categoryCtrl.text.isEmpty ? null : _categoryCtrl.text,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_rounded, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      ),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _categoryCtrl.text = val;
            _isOthersSelected = val == 'Others';
            if (!_isOthersSelected) {
              _customCategoryCtrl.clear();
            }
          });
        }
      },
      validator: (val) => val == null ? 'Please select a category' : null,
    );
  }

  Widget _buildCustomCategoryField() {
    return TextFormField(
      controller: _customCategoryCtrl,
      maxLength: 30,
      decoration: InputDecoration(
        labelText: 'Custom Category',
        hintText: 'Enter custom reminder category',
        prefixIcon: Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        counterText: '',
      ),
      validator: (val) {
        if (!_isOthersSelected) return null;
        if (val == null || val.trim().isEmpty) {
          return 'Please enter a custom category';
        }
        return null;
      },
    );
  }

  Widget _buildRepeatDropdown() {
    return DropdownButtonFormField<RepeatType>(
      initialValue: _repeatType,
      decoration: InputDecoration(
        labelText: 'Repeat Option',
        prefixIcon: Icon(Icons.repeat_rounded, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      ),
      items: RepeatType.values.map((rt) => DropdownMenuItem(value: rt, child: Text(rt.displayName))).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _repeatType = val);
      },
    );
  }

  Widget _buildPickerCard(String label, String value, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
