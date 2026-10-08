import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/database_helper.dart';
import '../services/heuristic_parser.dart';
import '../services/receipt_storage_service.dart';

class ReviewReceiptScreen extends StatefulWidget {
  final File imageFile;
  final ParsedReceiptResult parsedResult;

  const ReviewReceiptScreen({
    super.key,
    required this.imageFile,
    required this.parsedResult,
  });

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.parsedResult.merchant ?? '',
    );

    final amountVal = widget.parsedResult.amount;
    _amountController = TextEditingController(
      text: amountVal != null ? amountVal.toStringAsFixed(0) : '',
    );

    _selectedDate = widget.parsedResult.date ?? DateTime.now();
    _selectedCategory = widget.parsedResult.suggestedCategory;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      // 1. Cache thumbnail image to app persistent storage
      final cachedImagePath = await ReceiptStorageService.saveReceiptImage(widget.imageFile);

      // 2. Parse final amount
      final cleanAmountText = _amountController.text.replaceAll(',', '').replaceAll('.', '').trim();
      final amount = double.tryParse(cleanAmountText) ?? 0.0;

      // 3. Create model
      final transaction = ExpenseTransaction(
        id: const Uuid().v4(),
        merchant: _merchantController.text.trim().isEmpty
            ? 'Unknown Merchant'
            : _merchantController.text.trim(),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        imagePath: cachedImagePath,
        rawOcrText: widget.parsedResult.rawLines.join('\n'),
        createdAt: DateTime.now(),
      );

      // 4. Insert into SQLite
      await DatabaseHelper.instance.insertTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense transaction saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Receipt Image Preview Card
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        widget.imageFile,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'On-Device OCR Parsed',
                                style: TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Total Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Total Amount (VND)',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'đ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Heuristically extracted from receipt',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter amount';
                  final numVal = double.tryParse(val.replaceAll(',', '').replaceAll('.', ''));
                  if (numVal == null || numVal <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Merchant Field
              TextFormField(
                controller: _merchantController,
                decoration: InputDecoration(
                  labelText: 'Merchant / Store Name',
                  prefixIcon: const Icon(Icons.storefront),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter merchant name';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Transaction Date Selector
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Transaction Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.edit_calendar, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              Text(
                'Expense Category',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    label: Text(cat.displayName),
                    selected: isSelected,
                    selectedColor: cat.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Expandable Raw OCR Text
              ExpansionTile(
                title: const Text('Inspect Raw OCR Text', style: TextStyle(fontSize: 14)),
                leading: const Icon(Icons.description_outlined, size: 20),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      widget.parsedResult.rawLines.join('\n'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Action Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveTransaction,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Saving...' : 'Confirm & Save Transaction',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

