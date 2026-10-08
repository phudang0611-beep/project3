import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';

class TransactionListScreen extends StatefulWidget {
  final VoidCallback onScanPressed;

  const TransactionListScreen({
    super.key,
    required this.onScanPressed,
  });

  @override
  State<TransactionListScreen> createState() => TransactionListScreenState();
}

class TransactionListScreenState extends State<TransactionListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  List<ExpenseTransaction> _allTransactions = [];
  List<ExpenseTransaction> _filteredTransactions = [];
  ExpenseCategory? _filterCategory;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    setState(() => _isLoading = true);
    final list = await _dbHelper.getAllTransactions();
    if (mounted) {
      setState(() {
        _allTransactions = list;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    _filteredTransactions = _allTransactions.where((item) {
      final matchesCategory = _filterCategory == null || item.category == _filterCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          item.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.amount.toString().contains(_searchQuery);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _onCategorySelected(ExpenseCategory? category) {
    setState(() {
      _filterCategory = category;
      _applyFilter();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilter();
    });
  }

  Future<void> _deleteItem(ExpenseTransaction transaction) async {
    await _dbHelper.deleteTransaction(transaction.id);
    await loadTransactions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted expense from ${transaction.merchant}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _dbHelper.insertTransaction(transaction);
              await loadTransactions();
            },
          ),
        ),
      );
    }
  }

  void _showReceiptModal(ExpenseTransaction transaction) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transaction.merchant,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (transaction.imagePath != null && File(transaction.imagePath!).existsSync())
                Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(transaction.imagePath!),
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('No receipt image available'),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(transaction.date)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    '${_currencyFormat.format(transaction.amount)} đ',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
              if (transaction.rawOcrText != null && transaction.rawOcrText!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ExpansionTile(
                  title: const Text('Raw OCR Text', style: TextStyle(fontSize: 12)),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey.shade100,
                      child: Text(
                        transaction.rawOcrText!,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Category Filter Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // Search field
              TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search merchant or amount...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Category filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterCategory == null,
                      onSelected: (_) => _onCategorySelected(null),
                    ),
                    const SizedBox(width: 8),
                    ...ExpenseCategory.values.map((cat) {
                      final isSelected = _filterCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                          label: Text(cat.displayName),
                          selected: isSelected,
                          selectedColor: cat.color.withValues(alpha: 0.85),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                          onSelected: (_) => _onCategorySelected(cat),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Transactions List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _allTransactions.isEmpty
                                ? 'No receipts scanned yet'
                                : 'No matching transactions found',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: widget.onScanPressed,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Scan Your First Receipt'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadTransactions,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredTransactions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _filteredTransactions[index];
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Expense?'),
                                  content: Text('Delete receipt from ${item.merchant}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _deleteItem(item),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                onTap: () => _showReceiptModal(item),
                                leading: CircleAvatar(
                                  backgroundColor: item.category.color.withValues(alpha: 0.18),
                                  child: Icon(item.category.icon, color: item.category.color),
                                ),
                                title: Text(
                                  item.merchant,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${DateFormat('dd/MM/yyyy').format(item.date)} • ${item.category.displayName}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_currencyFormat.format(item.amount)} đ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (item.imagePath != null) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.receipt, size: 16, color: Colors.grey),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

