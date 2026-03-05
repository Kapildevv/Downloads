import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:howealthy1/l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class SendReportPage extends StatefulWidget {
  final List<QueryDocumentSnapshot> allDocs;
  const SendReportPage({super.key, required this.allDocs});
  @override
  State<SendReportPage> createState() => _SendReportPageState();
}

class _SendReportPageState extends State<SendReportPage> {
  String _selectedPeriod = 'Current Month';
  String _selectedFileType = 'Document (Word)';
  DateTimeRange? _customRange;
  bool _isLoading = false;
  final List<String> _periods = [
    'Current Month',
    'Previous Month',
    'Current Quarter',
    'Previous Quarter',
    'Current Financial Year',
    'Previous Financial Year',
    'Current Year',
    'Previous Year',
    'Custom Date Range'
  ];
  final List<String> _fileTypes = ['Document (Word)', 'Excel (CSV)'];

  DateTimeRange _calculateDateRange() {
    DateTime now = DateTime.now();
    DateTime start = now, end = now;
    if (_selectedPeriod == 'Current Month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59);
    } else if (_selectedPeriod == 'Previous Month') {
      start = DateTime(now.year, now.month - 1, 1);
      end = DateTime(now.year, now.month, 0, 23, 59);
    } else if (_selectedPeriod == 'Current Year') {
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31, 23, 59);
    } else if (_selectedPeriod == 'Previous Year') {
      start = DateTime(now.year - 1, 1, 1);
      end = DateTime(now.year - 1, 12, 31, 23, 59);
    } else if (_selectedPeriod == 'Current Financial Year') {
      int startYear = now.month < 4 ? now.year - 1 : now.year;
      start = DateTime(startYear, 4, 1);
      end = DateTime(startYear + 1, 3, 31, 23, 59);
    } else if (_selectedPeriod == 'Previous Financial Year') {
      int startYear = (now.month < 4 ? now.year - 1 : now.year) - 1;
      start = DateTime(startYear, 4, 1);
      end = DateTime(startYear + 1, 3, 31, 23, 59);
    } else if (_selectedPeriod == 'Current Quarter') {
      int quarter = ((now.month - 1) / 3).floor() + 1;
      start = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
      end = DateTime(now.year, quarter * 3 + 1, 0, 23, 59);
    } else if (_selectedPeriod == 'Previous Quarter') {
      int quarter = ((now.month - 1) / 3).floor() + 1;
      int prevQ = quarter - 1;
      int year = now.year;
      if (prevQ == 0) {
        prevQ = 4;
        year--;
      }
      start = DateTime(year, (prevQ - 1) * 3 + 1, 1);
      end = DateTime(year, prevQ * 3 + 1, 0, 23, 59);
    } else if (_selectedPeriod == 'Custom Date Range' && _customRange != null) {
      return _customRange!;
    }
    return DateTimeRange(start: start, end: end);
  }

  Future<void> _generateAndSend() async {
    setState(() => _isLoading = true);
    try {
      DateTimeRange range = _calculateDateRange();
      List<Map<String, dynamic>> filteredTxns = [];
      double totalIncome = 0;
      double totalExpense = 0;
      for (var doc in widget.allDocs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime date = DateTime.parse(data['date']);
        if (date.isAfter(range.start) && date.isBefore(range.end)) {
          filteredTxns.add(data);
          if (data['type'] == 'Credit') {
            totalIncome += (data['amount'] as num).toDouble();
          }
          if (data['type'] == 'Debit') {
            totalExpense += (data['amount'] as num).toDouble();
          }
        }
      }
      double savings = totalIncome - totalExpense;
      String dateDisplayStr =
          "(${DateFormat('dd-MMM-yy').format(range.start)} to ${DateFormat('dd-MMM-yy').format(range.end)})";
      final fileDateFormat = DateFormat('yyyy_MM_dd');
      String startStr = fileDateFormat.format(range.start);
      String endStr = fileDateFormat.format(range.end);
      String baseFileName = "Howealthy_${startStr}_to_$endStr";
      String fileContent = "";
      String fileName = "";
      if (_selectedFileType.contains("Document")) {
        fileName = "$baseFileName.doc";
        fileContent =
            """PERFORMANCE REPORT\nPeriod: $dateDisplayStr\n\nSUBJECT: Financial Performance Overview\n\nWe have analyzed your financial performance for the period $dateDisplayStr.\n\nIMPROVEMENT SUMMARY:\nTo improve your savings, consider reviewing your top expense categories. \nTry to adhere strictly to the 50/30/20 rule. \nBased on this period, your savings rate is ${totalIncome > 0 ? ((savings / totalIncome) * 100).toStringAsFixed(1) : 0}%.\n\nSUMMARY TABLE:\n--------------------------------------------------\n| Metric          | Amount (INR)                 |\n--------------------------------------------------\n| Total Income    | ₹${totalIncome.toStringAsFixed(2).padRight(20)} |\n| Total Expense   | ₹${totalExpense.toStringAsFixed(2).padRight(20)} |\n| Net Savings     | ₹${savings.toStringAsFixed(2).padRight(20)}      |\n--------------------------------------------------\n\nTRANSACTION DETAILS:\n${filteredTxns.map((e) => "${e['date'].substring(0, 10)} | ${e['category'].padRight(10)} | ₹${e['amount']}").join('\n')}\n""";
      } else {
        fileName = "$baseFileName.csv";
        fileContent =
            "Date,Category,Type,Amount,Note\n${filteredTxns.map((e) => "${e['date']},${e['category']},${e['type']},${e['amount']},${e['body']?.replaceAll(',', ' ')}").join('\n')}";
      }
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(fileContent);
      await Share.shareXFiles([XFile(file.path)],
          text: "Please find attached the financial report: $fileName",
          subject: "Financial Report $dateDisplayStr");
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            title: Text(l10n.generateReport), backgroundColor: Colors.black),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.selectPeriod,
                      style: const TextStyle(color: AppColors.darkTextSecondary)),
                  const SizedBox(height: 5),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: AppColors.darkTextSecondary,
                          borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                              value: _selectedPeriod,
                              dropdownColor: AppColors.darkTextSecondary,
                              style: const TextStyle(color: Colors.white),
                              items: _periods
                                  .map((p) => DropdownMenuItem(
                                      value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (val) async {
                                setState(() => _selectedPeriod = val!);
                                if (val == 'Custom Date Range') {
                                  var picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) => Theme(
                                          data: ThemeData.dark().copyWith(
                                              colorScheme:
                                                  const ColorScheme.dark(
                                                      primary:
                                                          Colors.tealAccent)),
                                          child: child!));
                                  if (picked != null) {
                                    setState(() => _customRange = picked);
                                  }
                                }
                              }))),
                  const SizedBox(height: 20),
                  Text(l10n.fileType,
                      style: const TextStyle(color: AppColors.darkTextSecondary)),
                  const SizedBox(height: 5),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: AppColors.darkTextSecondary,
                          borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                              value: _selectedFileType,
                              dropdownColor: AppColors.darkTextSecondary,
                              style: const TextStyle(color: Colors.white),
                              items: _fileTypes
                                  .map((f) => DropdownMenuItem(
                                      value: f, child: Text(f)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedFileType = val!)))),
                  const SizedBox(height: 50),
                  SizedBox(
                    height: 50,
                    child: Semantics(
                      button: true,
                      label: l10n.generateAndSend,
                      child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _generateAndSend,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.share, color: Colors.black),
                          label: Text(
                              _isLoading
                                  ? l10n.generating
                                  : l10n.generateAndSend,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16))),
                    ),
                  )
                ])));
  }
}
