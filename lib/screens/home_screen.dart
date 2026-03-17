// ============================================================
// screens/home_screen.dart
// SCREEN 1: Home / Dashboard
// Shows overall balance, income/expense summary cards,
// and the 5 most recent transactions.
// ============================================================

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import 'transactions_screen.dart';
import 'add_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();

  // Summary data loaded from DB
  double _balance = 0;
  double _income = 0;
  double _expense = 0;

  // Latest transactions for the preview list
  List<Transaction> _recentTransactions = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Fetch summary + recent transactions from SQLite
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _db.getSummary();
      final all = await _db.getAllTransactions();

      setState(() {
        _balance = summary['balance'] ?? 0;
        _income = summary['income'] ?? 0;
        _expense = summary['expense'] ?? 0;
        // Show only the 5 most recent on the home screen
        _recentTransactions = all.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryPurple,
        backgroundColor: AppTheme.surfaceCard,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar with greeting ──────────────────────
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: AppTheme.primaryDark,
              flexibleSpace: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _greeting(),
                            style: AppTheme.bodySmall,
                          ),
                          const Text(
                            'Daromadim', // my finances
                            style: AppTheme.headlineMedium,
                          ),
                        ],
                      ),
                      // Notification/settings icon
                      GlassCard(
                        padding: const EdgeInsets.all(10),
                        borderRadius: 14,
                        onTap: () {},
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppTheme.textSecondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Main content ───────────────────────────────
            SliverToBoxAdapter(
              child: _isLoading
                  ? const SizedBox(
                      height: 400,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Balance hero card ──────────────
                          _BalanceCard(
                            balance: _balance,
                            income: _income,
                            expense: _expense,
                          ),
                          const SizedBox(height: 28),

                          // ── Quick action buttons ───────────
                          _QuickActions(onRefresh: _loadData),
                          const SizedBox(height: 28),

                          // ── Recent transactions header ─────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Transactions',
                                style: AppTheme.titleLarge,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TransactionsScreen(),
                                    ),
                                  ).then((_) => _loadData());
                                },
                                child: const Text(
                                  'See all',
                                  style: TextStyle(
                                    color: AppTheme.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Recent transactions list ───────
                          if (_recentTransactions.isEmpty)
                            const EmptyState()
                          else
                            ...List.generate(
                              _recentTransactions.length,
                              (i) {
                                final tx = _recentTransactions[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: TransactionTile(
                                    transaction: tx,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditScreen(
                                              transaction: tx),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                    onDelete: () async {
                                      await _db.deleteTransaction(tx.id!);
                                      _loadData();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Transaction deleted'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 100), // FAB clearance
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

      // ── FAB: Add transaction ─────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditScreen()),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 🌙';
  }
}

// ─────────────────────────────────────────────────────────────
// _BalanceCard — hero card showing total balance
// ─────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accentCyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Total Balance', style: AppTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),

          // Balance amount
          Text(
            Formatters.currency(balance.abs()),
            style: AppTheme.amountLarge.copyWith(
              color: isPositive ? AppTheme.textPrimary : AppTheme.expenseRose,
            ),
          ),
          if (!isPositive)
            const Text(
              'Deficit',
              style: TextStyle(color: AppTheme.expenseRose, fontSize: 12),
            ),
          const SizedBox(height: 20),

          // Income / Expense row
          Row(
            children: [
              Expanded(
                child: SummaryChip(
                  label: 'Income',
                  amount: income,
                  isIncome: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryChip(
                  label: 'Expenses',
                  amount: expense,
                  isIncome: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _QuickActions — row of shortcut buttons
// ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onRefresh;

  const _QuickActions({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.add_circle_outline_rounded,
          label: 'Add',
          color: AppTheme.primaryPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditScreen()),
            ).then((_) => onRefresh());
          },
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.list_alt_rounded,
          label: 'All',
          color: AppTheme.accentCyan,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TransactionsScreen()),
            ).then((_) => onRefresh());
          },
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Income',
          color: AppTheme.incomeGreen,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransactionsScreen(
                  initialFilter: TransactionType.income,
                ),
              ),
            ).then((_) => onRefresh());
          },
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.arrow_downward_rounded,
          label: 'Expenses',
          color: AppTheme.expenseRose,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransactionsScreen(
                  initialFilter: TransactionType.expense,
                ),
              ),
            ).then((_) => onRefresh());
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
