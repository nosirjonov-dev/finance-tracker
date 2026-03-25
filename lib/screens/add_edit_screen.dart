// ============================================================
// screens/add_edit_screen.dart
// SCREEN 3: Add / Edit Transaction
// A form screen that handles both creating new transactions
// and editing existing ones. Includes:
//   - Title, description, amount text fields
//   - Income / Expense toggle
//   - Category selector grid
//   - Date picker
//   - Input validation
//   - Save to SQLite via DatabaseHelper
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class AddEditScreen extends StatefulWidget {
  // If null, we're adding; if provided, we're editing
  final Transaction? transaction;

  const AddEditScreen({super.key, this.transaction});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  // Form state
  TransactionType _type = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.other;
  DateTime _date = DateTime.now();

  bool _isSaving = false;
  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing an existing transaction
    if (_isEditing) {
      final tx = widget.transaction!;
      _titleController.text = tx.title;
      _descriptionController.text = tx.description;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _type = tx.type;
      _category = tx.category;
      _date = tx.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Validates and saves (insert or update) the transaction
  Future<void> _save() async {
    // Validate all form fields
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final now = DateTime.now();

      if (_isEditing) {
        // UPDATE existing transaction
        final updated = widget.transaction!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          amount: amount,
          type: _type,
          category: _category,
          date: _date,
        );
        await _db.updateTransaction(updated);
      } else {
        // INSERT new transaction
        final newTx = Transaction(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          amount: amount,
          type: _type,
          category: _category,
          date: _date,
          createdAt: now,
        );
        await _db.insertTransaction(newTx);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Transaction updated successfully!'
                  : 'Transaction added successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
        );
      }
    }
  }

  /// Opens native date picker
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryPurple,
            surface: AppTheme.surfaceCard,
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == TransactionType.income;
    final typeColor = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRose;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (_isEditing)
            // Delete button in edit mode
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.expenseRose),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surfaceCard,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Delete Transaction',
                        style: AppTheme.headlineMedium),
                    content: Text(
                      'Delete "${widget.transaction!.title}"?',
                      style: AppTheme.bodyLarge
                          .copyWith(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel',
                            style:
                                TextStyle(color: AppTheme.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.expenseRose,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await _db.deleteTransaction(widget.transaction!.id!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction deleted')),
                  );
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── Income / Expense toggle ────────────────────
            GlassCard(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  _TypeButton(
                    label: 'Xarajat', //Expense
                    icon: Icons.arrow_downward_rounded,
                    color: AppTheme.expenseRose,
                    isSelected: _type == TransactionType.expense,
                    onTap: () =>
                        setState(() => _type = TransactionType.expense),
                  ),
                  _TypeButton(
                    label: 'Darmomad', // income
                    icon: Icons.arrow_upward_rounded,
                    color: AppTheme.incomeGreen,
                    isSelected: _type == TransactionType.income,
                    onTap: () =>
                        setState(() => _type = TransactionType.income),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Amount input ───────────────────────────────
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount', style: AppTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter an amount';
                            }
                            final val = double.tryParse(v.trim());
                            if (val == null || val <= 0) {
                              return 'Enter a valid positive amount';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Title field ────────────────────────────────
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: AppTheme.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. Grocery Shopping',
                prefixIcon: Icon(Icons.title_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 2) return 'Title is too short';
                if (v.trim().length > 60) return 'Title is too long';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Description field ──────────────────────────
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              style: AppTheme.bodyLarge,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add a note...',
                prefixIcon: Icon(Icons.notes_rounded,
                    color: AppTheme.textSecondary, size: 20),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            // ── Date picker ────────────────────────────────
            GlassCard(
              onTap: _pickDate,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date', style: AppTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.dateLong(_date),
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textMuted),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Category selector ──────────────────────────
            const Text('Category', style: AppTheme.titleLarge),
            const SizedBox(height: 12),
            CategorySelector(
              selected: _category,
              onSelect: (cat) => setState(() => _category = cat),
            ),
            const SizedBox(height: 32),

            // ── Save button ────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isIncome ? AppTheme.incomeGreen : AppTheme.primaryPurple,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Save Changes'
                            : 'Add ${_type == TransactionType.income ? "Income" : "Expense"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _TypeButton — income or expense selection button
// ─────────────────────────────────────────────────────────────
class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? color : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
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
