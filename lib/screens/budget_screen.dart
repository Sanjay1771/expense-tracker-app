import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_details_dialog.dart';
import 'add_edit_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

enum BudgetSortOption {
  highestBudget,
  lowestBudget,
  mostRemaining,
  leastRemaining,
  alphabetical,
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetService = BudgetService();
  
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  
  List<BudgetModel> _budgets = [];
  bool _isLoading = true;
  
  String _searchQuery = '';
  BudgetSortOption _sortOption = BudgetSortOption.highestBudget;
  
  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    final fetched = await _budgetService.getBudgets(_currentMonth, _currentYear);
    if (mounted) {
      setState(() {
        _budgets = fetched;
        _isLoading = false;
      });
    }
  }

  List<BudgetModel> get _filteredAndSortedBudgets {
    var list = _budgets.where((b) => b.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    switch (_sortOption) {
      case BudgetSortOption.highestBudget:
        list.sort((a, b) => b.budgetAmount.compareTo(a.budgetAmount));
        break;
      case BudgetSortOption.lowestBudget:
        list.sort((a, b) => a.budgetAmount.compareTo(b.budgetAmount));
        break;
      case BudgetSortOption.mostRemaining:
        list.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
        break;
      case BudgetSortOption.leastRemaining:
        list.sort((a, b) => a.remainingAmount.compareTo(b.remainingAmount));
        break;
      case BudgetSortOption.alphabetical:
        list.sort((a, b) => a.category.compareTo(b.category));
        break;
    }
    
    return list;
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth += delta;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
    _loadBudgets();
  }

  void _showBudgetDetails(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (_) => BudgetDetailsDialog(
        budget: budget,
        onBudgetDeleted: _loadBudgets,
        onBudgetUpdated: _loadBudgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedBudgets = _filteredAndSortedBudgets;
    
    double totalBudget = _budgets.fold(0, (sum, b) => sum + b.budgetAmount);
    double totalSpent = _budgets.fold(0, (sum, b) => sum + b.spentAmount);
    double totalRemaining = totalBudget - totalSpent;
    double totalProgress = totalBudget > 0 ? (totalSpent / totalBudget) : 0;
    
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Budget Planner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBudgets,
        child: Column(
          children: [
            // Month Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime(_currentYear, _currentMonth)),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),
            
            // Analytics Header
            if (_budgets.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text('Total Monthly Budget', style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8))),
                      const SizedBox(height: 4),
                      Text(formatter.format(totalBudget), style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat('Spent', formatter.format(totalSpent), theme.colorScheme.onPrimary),
                          _buildMiniStat('Remaining', formatter.format(totalRemaining), theme.colorScheme.onPrimary),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: totalProgress > 1.0 ? 1.0 : totalProgress,
                        backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Search & Sort
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search categories...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<BudgetSortOption>(
                      value: _sortOption,
                      icon: const Icon(Icons.sort_rounded),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: BudgetSortOption.highestBudget, child: Text('Highest Budget')),
                        DropdownMenuItem(value: BudgetSortOption.lowestBudget, child: Text('Lowest Budget')),
                        DropdownMenuItem(value: BudgetSortOption.mostRemaining, child: Text('Most Remaining')),
                        DropdownMenuItem(value: BudgetSortOption.leastRemaining, child: Text('Least Remaining')),
                        DropdownMenuItem(value: BudgetSortOption.alphabetical, child: Text('Alphabetical')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sortOption = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // List
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _budgets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text('No budget created for this month.', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () async {
                              final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBudgetScreen()));
                              if (res == true) _loadBudgets();
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create Budget'),
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: displayedBudgets.length,
                      itemBuilder: (context, index) {
                        return BudgetCard(
                          budget: displayedBudgets[index],
                          onTap: () => _showBudgetDetails(displayedBudgets[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _budgets.isNotEmpty ? FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBudgetScreen()));
          if (res == true) _loadBudgets();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Budget'),
      ) : null,
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
