// ============================================================
// models/transaction.dart
// Defines the Transaction data model used throughout the app.
// Maps directly to the 'transactions' table in SQLite.
// ============================================================

/// Enum representing the type of a financial transaction
enum TransactionType { income, expense }

/// Enum for transaction categories — used for filtering and display
enum TransactionCategory {
  food,
  transport,
  shopping,
  entertainment,
  health,
  housing,
  salary,
  freelance,
  investment,
  other,
}

/// Extension to get display name and icon code point from category
extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.food:
        return 'Food & Dining';
      case TransactionCategory.transport:
        return 'Transport';
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.health:
        return 'Health';
      case TransactionCategory.housing:
        return 'Housing';
      case TransactionCategory.salary:
        return 'Salary';
      case TransactionCategory.freelance:
        return 'Freelance';
      case TransactionCategory.investment:
        return 'Investment';
      case TransactionCategory.other:
        return 'Other';
    }
  }

  int get iconCodePoint {
    switch (this) {
      case TransactionCategory.food:
        return 0xe25a; // restaurant
      case TransactionCategory.transport:
        return 0xe531; // directions_car
      case TransactionCategory.shopping:
        return 0xe8cc; // shopping_bag
      case TransactionCategory.entertainment:
        return 0xe404; // movie
      case TransactionCategory.health:
        return 0xe548; // favorite (heart)
      case TransactionCategory.housing:
        return 0xe88a; // home
      case TransactionCategory.salary:
        return 0xe263; // attach_money
      case TransactionCategory.freelance:
        return 0xe8f9; // work
      case TransactionCategory.investment:
        return 0xe8d5; // trending_up
      case TransactionCategory.other:
        return 0xe8b8; // more_horiz
    }
  }
}

/// The main Transaction model
class Transaction {
  // Unique identifier (nullable for new, unsaved transactions)
  final int? id;

  // Human-readable title
  final String title;

  // Optional longer description
  final String description;

  // Amount in the user's currency (stored as REAL in SQLite)
  final double amount;

  // income or expense
  final TransactionType type;

  // Category for grouping/filtering
  final TransactionCategory category;

  // When the transaction occurred (stored as ISO8601 string in SQLite)
  final DateTime date;

  // When the record was created (for sorting)
  final DateTime createdAt;

  const Transaction({
    this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.createdAt,
  });

  // ── SQLite conversion ──────────────────────────────────────

  /// Convert a Transaction into a Map for SQLite insertion/update
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      // Store enum as string so it's human-readable in the DB
      'type': type.name,
      'category': category.name,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a Transaction from a SQLite row Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TransactionCategory.other,
      ),
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Return a copy with optional field overrides (immutable update pattern)
  Transaction copyWith({
    int? id,
    String? title,
    String? description,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Transaction(id: $id, title: $title, amount: $amount, type: ${type.name})';
}
