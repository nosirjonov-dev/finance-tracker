// ============================================================
// widgets/common_widgets.dart
// Reusable UI components used across multiple screens.
// ============================================================

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

// ─────────────────────────────────────────────────────────────
// GlassCard — a frosted glass-style card with gradient border
// ─────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppTheme.primaryPurple.withOpacity(0.1),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color ?? AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppTheme.borderSubtle,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SummaryChip — small stat badge (e.g., "+$4,500 Income")
// ─────────────────────────────────────────────────────────────
class SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final bool isIncome;

  const SummaryChip({
    super.key,
    required this.label,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRose;
    final gradient = isIncome ? AppTheme.incomeGradient : AppTheme.expenseGradient;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currencyCompact(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TransactionTile — list item for a single transaction
// ─────────────────────────────────────────────────────────────
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = AppTheme.categoryColors[transaction.category.name] ??
        AppTheme.textMuted;
    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRose;
    final amountPrefix = isIncome ? '+' : '-';

    return Dismissible(
      key: Key('tx-${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expenseRose.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.expenseRose),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => _DeleteConfirmDialog(
            title: transaction.title,
            onConfirm: () => Navigator.pop(ctx, true),
            onCancel: () => Navigator.pop(ctx, false),
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Category icon badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                IconData(
                  transaction.category.iconCodePoint,
                  fontFamily: 'MaterialIcons',
                ),
                color: categoryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          transaction.category.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.dateRelative(transaction.date),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount
            Text(
              '$amountPrefix${Formatters.currency(transaction.amount)}',
              style: TextStyle(
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

// ─────────────────────────────────────────────────────────────
// _DeleteConfirmDialog — confirmation dialog for deletion
// ─────────────────────────────────────────────────────────────
class _DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmDialog({
    required this.title,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete Transaction', style: AppTheme.headlineMedium),
      content: Text(
        'Are you sure you want to delete "$title"? This action cannot be undone.',
        style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.expenseRose,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EmptyState — shown when list has no items
// ─────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    this.message = 'No transactions yet.\nTap + to add your first one.',
    this.icon = Icons.receipt_long_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CategorySelector — grid of category option buttons
// ─────────────────────────────────────────────────────────────
class CategorySelector extends StatelessWidget {
  final TransactionCategory selected;
  final ValueChanged<TransactionCategory> onSelect;

  const CategorySelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TransactionCategory.values.map((cat) {
        final isSelected = cat == selected;
        final color = AppTheme.categoryColors[cat.name] ?? AppTheme.textMuted;

        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : AppTheme.borderSubtle,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                  size: 15,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  cat.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? color : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
