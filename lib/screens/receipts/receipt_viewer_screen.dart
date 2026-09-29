import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expensetracker/models/transaction.dart';
import 'package:expensetracker/providers/app_state.dart';
import 'package:expensetracker/theme/app_theme.dart';
import 'package:expensetracker/screens/transactions/transaction_detail_screen.dart';

class ReceiptViewerScreen extends StatefulWidget {
  final String imagePath;
  final TransactionItem? transaction;
  final AppState state;
  final Function(String?)? onReceiptUpdated;

  const ReceiptViewerScreen({
    super.key,
    required this.imagePath,
    this.transaction,
    required this.state,
    this.onReceiptUpdated,
  });

  @override
  State<ReceiptViewerScreen> createState() => _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends State<ReceiptViewerScreen> {
  late String _currentPath;
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentPath = widget.imagePath;
  }

  Future<void> _replaceReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _currentPath = picked.path;
      });
      if (widget.transaction != null) {
        widget.transaction!.receiptImagePath = picked.path;
        widget.state.updateTransaction(widget.transaction!);
      }
      widget.onReceiptUpdated?.call(picked.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt updated.')),
        );
      }
    }
  }

  Future<void> _deleteReceipt() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Receipt?'),
        content: const Text('Are you sure you want to detach this receipt from the transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.expenseRed)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (widget.transaction != null) {
        widget.transaction!.receiptImagePath = null;
        widget.state.updateTransaction(widget.transaction!);
      }
      widget.onReceiptUpdated?.call(null);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(_currentPath);
    final exists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.transaction?.merchant.isNotEmpty == true
              ? 'Receipt • ${widget.transaction!.merchant}'
              : 'Receipt Viewer',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Replace Receipt',
            onPressed: _replaceReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            tooltip: 'Delete Receipt',
            onPressed: _deleteReceipt,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: exists
                ? InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text('Unable to render receipt image file.', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  )
                : const Center(
                    child: Text('Receipt image not found on local storage.', style: TextStyle(color: Colors.white70)),
                  ),
          ),
          if (widget.transaction != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: SafeArea(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 20),
                  label: const Text('View Associated Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionDetailScreen(
                          state: widget.state,
                          transaction: widget.transaction!,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
