import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:howealthy1/l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class AlertSchedulerPage extends StatefulWidget {
  final List<QueryDocumentSnapshot> allDocs;
  const AlertSchedulerPage({super.key, required this.allDocs});

  @override
  State<AlertSchedulerPage> createState() => _AlertSchedulerPageState();
}

class _AlertSchedulerPageState extends State<AlertSchedulerPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  String _selectedFrequency = 'Monthly';
  DateTimeRange? _customRange;
  bool _isLoading = false;
  final List<String> _frequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
    'Custom Range'
  ];
  final List<String> _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  final List<int> _selectedDays = [];

  CollectionReference get _alertsCollection {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('alerts');
  }

  double _calculateSpent(Map<String, dynamic> alertData) {
    double spent = 0;
    DateTime start = DateTime.parse(alertData['startDate']);
    DateTime end = DateTime.parse(alertData['endDate']);
    for (var doc in widget.allDocs) {
      Map<String, dynamic> txn = doc.data() as Map<String, dynamic>;
      if (txn['type'] == 'Debit') {
        DateTime txnDate = DateTime.parse(txn['date']);
        if (txnDate.isAfter(start) && txnDate.isBefore(end)) {
          spent += (txn['amount'] as num).toDouble();
        }
      }
    }
    return spent;
  }

  Future<void> _addAlert() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      DateTime now = DateTime.now();
      DateTime start = now, end = now;
      if (_selectedFrequency == 'Daily') {
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (_selectedFrequency == 'Weekly') {
        start = now.subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
      } else if (_selectedFrequency == 'Monthly') {
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59);
      } else if (_selectedFrequency == 'Yearly') {
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, 12, 31, 23, 59);
      } else if (_selectedFrequency == 'Custom Range' && _customRange != null) {
        start = _customRange!.start;
        end = _customRange!.end.add(const Duration(hours: 23, minutes: 59));
      }

      List<int> mappedDays = [];
      if (_selectedDays.contains(0)) mappedDays.add(7);
      if (_selectedDays.contains(1)) mappedDays.add(1);
      if (_selectedDays.contains(2)) mappedDays.add(2);
      if (_selectedDays.contains(3)) mappedDays.add(3);
      if (_selectedDays.contains(4)) mappedDays.add(4);
      if (_selectedDays.contains(5)) mappedDays.add(5);
      if (_selectedDays.contains(6)) mappedDays.add(6);

      await _alertsCollection.add({
        'frequency': _selectedFrequency,
        'limit': double.parse(_amountController.text),
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'repeatDays': mappedDays
      });

      _amountController.clear();
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.alertAdded)));
      }
    } catch (e) {
      debugPrint("Error adding alert: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.errorGeneric), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _deleteAlert(String id) async {
    try {
      await _alertsCollection.doc(id).delete();
    } catch (e) {
      debugPrint("Error deleting alert: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            title: Text(l10n.budgetAlerts), backgroundColor: Colors.black),
        body: Column(children: [
          Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.darkTextSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.darkTextSecondary)),
              child: Form(
                  key: _formKey,
                  child: Column(children: [
                    DropdownButtonFormField<String>(
                        initialValue: _selectedFrequency,
                        dropdownColor: AppColors.darkTextSecondary,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            labelText: l10n.frequency,
                            labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
                            enabledBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.darkTextSecondary)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8))),
                        items: _frequencies
                            .map((f) =>
                                DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) async {
                          setState(() => _selectedFrequency = val!);
                          if (val == 'Custom Range') {
                            var picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                builder: (context, child) => Theme(
                                    data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                            primary: Colors.tealAccent)),
                                    child: child!));
                            if (picked != null) {
                              setState(() => _customRange = picked);
                            }
                          }
                        }),
                    const SizedBox(height: 10),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(l10n.repeatOnDays,
                            style: const TextStyle(
                                color: AppColors.darkTextSecondary, fontSize: 12))),
                    const SizedBox(height: 5),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          bool isSelected = _selectedDays.contains(index);
                          return Semantics(
                            selected: isSelected,
                            label: _days[index],
                            child: GestureDetector(
                              onTap: () => setState(() => isSelected
                                  ? _selectedDays.remove(index)
                                  : _selectedDays.add(index)),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.tealAccent
                                        : AppColors.darkTextSecondary,
                                    shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(_days[index],
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        })),
                    const SizedBox(height: 15),
                    TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            labelText: l10n.limitAmount,
                            labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
                            prefixIcon: const Icon(Icons.currency_rupee,
                                color: Colors.tealAccent),
                            enabledBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppColors.darkTextSecondary)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            errorStyle:
                                const TextStyle(color: AppColors.error)),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return l10n.amountBlank;
                          }
                          if (double.tryParse(val) == null) {
                            return l10n.numbersOnly;
                          }
                          return null;
                        }),
                    const SizedBox(height: 10),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: _isLoading ? null : _addAlert,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent),
                            child: Text(l10n.setAlert,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold))))
                  ]))),
          const Divider(color: AppColors.darkTextSecondary),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: _alertsCollection
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                          child: Text(l10n.noActiveAlerts,
                              style: const TextStyle(color: AppColors.darkTextSecondary)));
                    }
                    return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          String id = docs[index].id;
                          DateTime start = DateTime.parse(data['startDate']);
                          DateTime end = DateTime.parse(data['endDate']);
                          final DateFormat formatter = DateFormat('dd-MMM-yy');
                          String dateRange =
                              "(${formatter.format(start)} to ${formatter.format(end)})";
                          double limit = (data['limit'] as num).toDouble();
                          double spent = _calculateSpent(data);
                          Color barColor = Colors.yellow;
                          if (spent > limit) barColor = AppColors.error;
                          if (spent < limit) barColor = AppColors.success;
                          double maxVal = (spent > limit ? spent : limit);
                          if (maxVal == 0) maxVal = 1;
                          double limitHeight = (limit / maxVal) * 60;
                          double spentHeight = (spent / maxVal) * 60;
                          return Semantics(
                            label:
                                '${data['frequency']} alert: limit ${limit.toInt()} rupees, spent ${spent.toInt()} rupees',
                            child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AppColors.darkTextSecondary,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Row(children: [
                                  Expanded(
                                      flex: 3,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                "${data['frequency']}\n$dateRange",
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                            const SizedBox(height: 6),
                                            Text("Limit: ₹${limit.toInt()}",
                                                style: const TextStyle(
                                                    color: AppColors.darkTextSecondary,
                                                    fontSize: 12)),
                                            Text("Spent: ₹${spent.toInt()}",
                                                style: TextStyle(
                                                    color: barColor,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ])),
                                  Expanded(
                                      flex: 2,
                                      child: SizedBox(
                                          height: 80,
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                          width: 12,
                                                          height:
                                                              limitHeight < 5
                                                                  ? 5
                                                                  : limitHeight,
                                                          decoration: BoxDecoration(
                                                              color:
                                                                  AppColors.darkTextSecondary,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          2))),
                                                      const SizedBox(height: 4),
                                                      const Text("Set",
                                                          style: TextStyle(
                                                              color:
                                                                  AppColors.darkTextSecondary,
                                                              fontSize: 9))
                                                    ]),
                                                Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                          width: 12,
                                                          height:
                                                              spentHeight < 5
                                                                  ? 5
                                                                  : spentHeight,
                                                          decoration: BoxDecoration(
                                                              color: barColor,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          2))),
                                                      const SizedBox(height: 4),
                                                      const Text("Used",
                                                          style: TextStyle(
                                                              color:
                                                                  AppColors.darkTextSecondary,
                                                              fontSize: 9))
                                                    ])
                                              ]))),
                                  Semantics(
                                    button: true,
                                    label: 'Delete alert',
                                    child: IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppColors.error),
                                        onPressed: () => _deleteAlert(id)),
                                  )
                                ])),
                          );
                        });
                  }))
        ]));
  }
}
