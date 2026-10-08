import 'package:flutter/material.dart';

import 'analytics_screen.dart';
import 'camera_scanner_screen.dart';
import 'transaction_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<TransactionListScreenState> _txListKey = GlobalKey();

  Future<void> _openCameraScanner() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
    );

    if (result == true) {
      // Reload transaction list if current tab is 0
      _txListKey.currentState?.loadTransactions();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Receipt Expenses' : 'Spending Analytics',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Mini-Project 3',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'OCR Expense Tracker',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Mini-Project 3: OCR Expense Tracker & Receipt Parser\n'
                    'Powered by Google ML Kit, SQLite & CustomPainter',
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TransactionListScreen(
            key: _txListKey,
            onScanPressed: _openCameraScanner,
          ),
          const AnalyticsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCameraScanner,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Bill', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.receipt_long,
                color: _currentIndex == 0 ? Theme.of(context).primaryColor : Colors.grey,
              ),
              tooltip: 'Transactions',
              onPressed: () => setState(() => _currentIndex = 0),
            ),
            const SizedBox(width: 48), // notch spacing for center FAB
            IconButton(
              icon: Icon(
                Icons.pie_chart,
                color: _currentIndex == 1 ? Theme.of(context).primaryColor : Colors.grey,
              ),
              tooltip: 'Analytics',
              onPressed: () => setState(() => _currentIndex = 1),
            ),
          ],
        ),
      ),
    );
  }
}
