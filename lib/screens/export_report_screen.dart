import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  final _db = DatabaseService();
  final _auth = AuthService();

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final uid = _auth.userId;
    final income = await _db.getTotalIncome(uid);
    final expense = await _db.getTotalExpense(uid);
    final cats = await _db.getExpensesByCategory(uid);
    final txns = await _db.getTransactions(uid);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Expense Tracker Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('MMMM yyyy').format(DateTime.now())),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfStat('Total Income', '₹${income.toStringAsFixed(0)}'),
              _pdfStat('Total Expense', '₹${expense.toStringAsFixed(0)}'),
              _pdfStat('Net Balance', '₹${(income - expense).toStringAsFixed(0)}'),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text('Category Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Category', 'Amount', 'Percentage'],
            data: cats.entries.map((e) {
              final pct = (e.value / expense * 100).toStringAsFixed(1);
              return [e.key, '₹${e.value.toStringAsFixed(0)}', '$pct%'];
            }).toList(),
          ),
          pw.SizedBox(height: 30),
          pw.Text('Recent Transactions', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Time', 'Title', 'Type', 'Amount'],
            data: txns.take(20).map((t) {
              return [
                DateFormat('MMM dd').format(t.date),
                DateFormat('hh:mm a').format(t.date),
                t.title,
                t.type.name.toUpperCase(),
                '₹${t.amount.toStringAsFixed(0)}',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        backgroundColor: AppTheme.bg,
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        maxPageWidth: 700,
        canChangePageFormat: false,
        canChangeOrientation: false,
        loadingWidget: const CircularProgressIndicator(color: AppTheme.neonBlue),
        pdfFileName: 'expense_report_${DateFormat('MMM_yyyy').format(DateTime.now())}.pdf',
        actions: [
            PdfPreviewAction(
                icon: const Icon(Icons.share),
                onPressed: (context, build, format) async {
                   final bytes = await build(format);
                   await Printing.sharePdf(bytes: bytes, filename: 'report.pdf');
                },
            )
        ],
      ),
    );
  }
}
