// ============================================================
// screens/transactions_screen.dart
// SCREEN 2: All Transactions / Database View
// Shows the full list of transactions with:
//   - Search by title/description
//   - Filter by type (All / Income / Expense)
//   - Sort by date or amount
//   - Swipe to delete (with confirm dialog)
//   - Pull to refresh
// ============================================================

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'add_edit_screen.dart';

class TransactionsScreen extends StatefulWidget {
  // Optional pre-set filter when navigated from quick actions
  final TransactionType? initialFilter;

  const TransactionsScreen({super.key, this.initialFilter});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<Transaction> _allTransactions = [];
  List<Transaction> _filtered = [];

  // Current filter state
  TransactionType? _typeFilter;
  _SortMode _sortMode = _SortMode.dateDesc;

  bool _isLoading = true;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.initialFilter;
    _loadTransactions();

    // Re-filter whenever search text changes
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Loads all transactions from SQLite
  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final txs = await _db.getAllTransactions();
      setState(() {
        _allTransactions = txs;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Applies search query + type filter + sort to _allTransactions
  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    var result = _allTransactions.where((tx) {
      // Type filter
      if (_typeFilter != null && tx.type != _typeFilter) return false;
      // Search filter
      if (query.isNotEmpty) {
        return tx.title.toLowerCase().contains(query) ||
            tx.description.toLowerCase().contains(query) ||
            tx.category.displayName.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Apply sort
    switch (_sortMode) {
      case _SortMode.dateDesc:
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortMode.dateAsc:
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SortMode.amountDesc:
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case _SortMode.amountAsc:
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    setState(() => _filtered = result);
  }

  Future<void> _deleteTransaction(Transaction tx) async {
    await _db.deleteTransaction(tx.id!);
    await _loadTransactions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: _showSearch
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: AppTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              )
            : const Text('Transactions'),
        actions: [
          // Toggle search bar
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                }
              });
            },
          ),
          // Sort menu
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort_rounded, color: AppTheme.textSecondary),
            color: AppTheme.surfaceCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            onSelected: (mode) {
              setState(() => _sortMode = mode);
              _applyFilters();
            },
            itemBuilder: (_) => [
              _sortMenuItem(_SortMode.dateDesc, 'Newest First',
                  Icons.arrow_downward_rounded),
              _sortMenuItem(_SortMode.dateAsc, 'Oldest First',
                  Icons.arrow_upward_rounded),
              _sortMenuItem(_SortMode.amountDesc, 'Highest Amount',
                  Icons.north_rounded),
              _sortMenuItem(_SortMode.amountAsc, 'Lowest Amount',
                  Icons.south_rounded),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter tabs ────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _FilterTabs(
              selected: _typeFilter,
              onSelect: (type) {
                setState(() => _typeFilter = type);
                _applyFilters();
              },
            ),
          ),

          // ── Results count ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} transaction${_filtered.length != 1 ? 's' : ''}',
                  style: AppTheme.bodySmall,
                ),
                if (_typeFilter != null || _searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _typeFilter = null;
                        _searchController.clear();
                        _showSearch = false;
                      });
                      _applyFilters();
                    },
                    child: const Text(
                      'Clear filters',
                      style: TextStyle(
                        color: AppTheme.primaryPurple,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Transaction list ───────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryPurple,
                    ),
                  )
                : _filtered.isEmpty
                    ? EmptyState(
                        message: _searchController.text.isNotEmpty
                            ? 'No results for "${_searchController.text}"'
                            : 'No transactions here yet.',
                        icon: Icons.search_off_rounded,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        color: AppTheme.primaryPurple,
                        backgroundColor: AppTheme.surfaceCard,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final tx = _filtered[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TransactionTile(
                                transaction: tx,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddEditScreen(transaction: tx),
                                    ),
                                  ).then((_) => _loadTransactions());
                                },
                                onDelete: () => _deleteTransaction(tx),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      // ── FAB ────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditScreen()),
          ).then((_) => _loadTransactions());
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  PopupMenuItem<_SortMode> _sortMenuItem(
      _SortMode mode, String label, IconData icon) {
    final isSelected = _sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isSelected
                  ? AppTheme.primaryPurple
                  : AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryPurple : AppTheme.textPrimary,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _FilterTabs — All / Income / Expense filter row
// ─────────────────────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onSelect;

  const _FilterTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tab(null, 'All', Icons.all_inclusive_rounded),
        const SizedBox(width: 8),
        _tab(TransactionType.income, 'Income', Icons.arrow_upward_rounded),
        const SizedBox(width: 8),
        _tab(TransactionType.expense, 'Expenses', Icons.arrow_downward_rounded),
      ],
    );
  }

  Widget _tab(TransactionType? type, String label, IconData icon) {
    final isSelected = selected == type;
    Color color;
    if (type == TransactionType.income) {
      color = AppTheme.incomeGreen;
    } else if (type == TransactionType.expense) {
      color = AppTheme.expenseRose;
    } else {
      color = AppTheme.primaryPurple;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderSubtle,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: isSelected ? color : AppTheme.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sort mode enum
enum _SortMode { dateDesc, dateAsc, amountDesc, amountAsc }
