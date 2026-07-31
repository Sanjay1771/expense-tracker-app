import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';
import '../screens/add_edit_budget_screen.dart';
import '../services/budget_service.dart';

class BudgetDetailsDialog extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onBudgetDeleted;
  final VoidCallback onBudgetUpdated;

  const BudgetDetailsDialog({
    super.key,
    required this.budget,
    required this.onBudgetDeleted,
    required this.onBudgetUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final monthName = DateFormat('MMMM yyyy').format(DateTime(budget.year, budget.month));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    budget.category,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    monthName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildStatRow(context, 'Budget Amount', formatter.format(budget.budgetAmount), Icons.account_balance_wallet_rounded),
            const SizedBox(height: 12),
            _buildStatRow(context, 'Spent Amount', formatter.format(budget.spentAmount), Icons.shopping_cart_rounded, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            _buildStatRow(context, 'Remaining', formatter.format(budget.remainingAmount), Icons.savings_rounded, color: budget.remainingAmount < 0 ? theme.colorScheme.error : Colors.green),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Utilization', style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(budget.progressPercentageString, style: theme.textTheme.titleSmall?.copyWith(color: budget.progressColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: budget.progressPercentage > 1.0 ? 1.0 : budget.progressPercentage,
                minHeight: 8,
                backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(budget.progressColor),
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDelete(context),
                    icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                    label: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _handleEdit(context),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text('This will only remove the budget tracking for this month. Your expenses will NOT be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Delete', style: TextStyle(color: Theme.of(c).colorScheme.error))),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      if (budget.id != null) {
        await BudgetService().deleteBudget(budget.id!);
        if (context.mounted) {
          Navigator.pop(context);
          onBudgetDeleted();
        }
      }
    }
  }

  void _handleEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditBudgetScreen(budget: budget)),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context);
      onBudgetUpdated();
    }
  }
}
