// Export Friends Report — PDF with ONLY friend wallet data
// Completely separate from main expense PDF
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_transaction_model.dart';
import '../theme/app_theme.dart';

class ExportFriendsReportScreen extends StatefulWidget {
  const ExportFriendsReportScreen({super.key});
  @override
  State<ExportFriendsReportScreen> createState() =>
      _ExportFriendsReportScreenState();
}

class _ExportFriendsReportScreenState extends State<ExportFriendsReportScreen> {
  Future<List<FriendTransactionModel>> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('friends_transactions')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs
        .map((d) => FriendTransactionModel.fromFirestore(d.id, d.data()))
        .toList();
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final txns = await _fetchData();

    double totalGiven = 0, totalReceived = 0;
    int pendingCount = 0, completedCount = 0;
    for (final tx in txns) {
      if (tx.isGiven) totalGiven += tx.amount;
      if (tx.isReceived) totalReceived += tx.amount;
      if (tx.isPending) pendingCount++;
      if (tx.isCompleted) completedCount++;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Friends Wallet Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('MMMM yyyy').format(DateTime.now())),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfStat('Total Given', '₹${totalGiven.toStringAsFixed(0)}'),
              _pdfStat(
                  'Total Received', '₹${totalReceived.toStringAsFixed(0)}'),
              _pdfStat('Pending', '$pendingCount'),
              _pdfStat('Completed', '$completedCount'),
            ],
          ),
          pw.SizedBox(height: 30),

          // Transaction table
          pw.Text('Friend Transactions',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: [
              'Friend',
              'Amount',
              'Type',
              'Due Date',
              'Status',
              'Added At'
            ],
            data: txns.map((t) {
              return [
                t.friendName,
                '₹${t.amount.toStringAsFixed(0)}',
                t.type.toUpperCase(),
                t.dueDate != null
                    ? DateFormat('MMM dd, yyyy').format(t.dueDate!)
                    : '—',
                t.status.toUpperCase(),
                DateFormat('MMM dd, hh:mm a').format(t.createdAt),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Column(children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
      pw.SizedBox(height: 4),
      pw.Text(value,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends Report'),
        backgroundColor: AppTheme.bg,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        maxPageWidth: 700,
        canChangePageFormat: false,
        canChangeOrientation: false,
        loadingWidget:
            const CircularProgressIndicator(color: AppTheme.neonBlue),
        pdfFileName:
            'friends_report_${DateFormat('MMM_yyyy').format(DateTime.now())}.pdf',
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.share),
            onPressed: (context, build, format) async {
              final bytes = await build(format);
              await Printing.sharePdf(
                  bytes: bytes, filename: 'friends_report.pdf');
            },
          ),
        ],
      ),
    );
  }
}
