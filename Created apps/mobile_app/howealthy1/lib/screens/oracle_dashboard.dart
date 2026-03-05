import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:howealthy1/l10n/app_localizations.dart';
import '../providers/data_pipeline.dart';
import '../services/clairvoyance_engine.dart';

import 'views/pnl_treemap_view.dart';
import 'views/infinite_transaction_view.dart';
import 'widgets/clairvoyance_tile.dart';
import 'widgets/prediction_card.dart';
import 'widgets/quick_add_expense.dart';
import 'widgets/dynamic_aura_background.dart';
import 'oracle_chat_page.dart';
import 'views/cashflow_sankey_view.dart';
import 'financial_stories_page.dart';

import '../models/insight.dart';
import '../services/spending_analyzer.dart';
import '../services/expense_predictor.dart';

import 'profile_page.dart';
import 'alert_scheduler_page.dart';
import 'send_report_page.dart';
import 'settings_page.dart';
import '../theme/app_colors.dart';

class OracleDashboard extends ConsumerStatefulWidget {
  const OracleDashboard({super.key});

  @override
  ConsumerState<OracleDashboard> createState() => _OracleDashboardState();
}

class _OracleDashboardState extends ConsumerState<OracleDashboard> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transactionStream = ref.watch(transactionsStreamProvider);

    double savingsRate = 0.0;
    if (transactionStream.hasValue) {
      final txns = transactionStream.value!;
      double totalExpense = txns
          .where((t) => t['type'] == 'Debit')
          .fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());
      double totalIncome = txns
          .where((t) => t['type'] == 'Credit')
          .fold(0, (sum, item) => sum + (item['amount'] as num).toDouble());
      if (totalIncome > 0) {
        savingsRate = (totalIncome - totalExpense) / totalIncome;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        SystemNavigator.pop();
      },
      child: DynamicAuraBackground(
        savingsRate: savingsRate,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Semantics(
              header: true,
              child: Text(l10n.theOracle,
                  style: const TextStyle(color: Colors.white)),
            ),
            elevation: 0,
          ),
          drawer: Drawer(
            backgroundColor: AppColors.lightTextPrimary,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF004D40), Colors.black],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Semantics(
                        excludeSemantics: true,
                        child: const Icon(Icons.account_balance_wallet,
                            color: Colors.tealAccent, size: 40),
                      ),
                      const SizedBox(height: 10),
                      Text(l10n.howealthyOracle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.operatorProfile,
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.white),
                    title: Text(l10n.operatorProfile,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilePage()));
                    },
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.alertMatrix,
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active,
                        color: Colors.white),
                    title: Text(l10n.alertMatrix,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AlertSchedulerPage(allDocs: [])));
                    },
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.generateReports,
                  child: ListTile(
                    leading: const Icon(Icons.share, color: Colors.white),
                    title: Text(l10n.generateReports,
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const SendReportPage(allDocs: [])));
                    },
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.environmentalControls,
                  child: ListTile(
                    leading:
                        const Icon(Icons.settings, color: Colors.tealAccent),
                    title: Text(l10n.environmentalControls,
                        style: const TextStyle(color: Colors.tealAccent)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsPage()));
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'chat_fab',
                backgroundColor: const Color(0xFF004D40),
                child: const Icon(Icons.auto_awesome, color: Colors.tealAccent),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OracleChatPage())),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'add_fab',
                backgroundColor: Colors.tealAccent,
                child: const Icon(Icons.bolt, color: Colors.black),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const QuickAddExpense(),
                ),
              ),
            ],
          ),
          body: transactionStream.when(
            loading: () => Center(
              child: Semantics(
                label: 'Loading transactions',
                child:
                    const CircularProgressIndicator(color: Colors.tealAccent),
              ),
            ),
            error: (error, stack) {
              debugPrint("Dashboard error: $error");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        l10n.errorGeneric,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(transactionsStreamProvider),
                        icon: const Icon(Icons.refresh, color: Colors.black),
                        label: Text(l10n.retry,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent),
                      ),
                    ],
                  ),
                ),
              );
            },
            data: (transactions) {
              final tabLabels = [
                l10n.tabPnl,
                l10n.tabTimeline,
                l10n.tabCashflow,
                l10n.tabMonth
              ];

              double totalExpense = transactions
                  .where((t) => t['type'] == 'Debit')
                  .fold(0,
                      (sum, item) => sum + (item['amount'] as num).toDouble());

              double totalIncome = transactions
                  .where((t) => t['type'] == 'Credit')
                  .fold(0,
                      (sum, item) => sum + (item['amount'] as num).toDouble());

              Map<String, double> expenseData = {};
              for (var t in transactions.where((t) => t['type'] == 'Debit')) {
                expenseData[t['category']] = (expenseData[t['category']] ?? 0) +
                    (t['amount'] as num).toDouble();
              }

              final now = DateTime.now();
              final currentMonthTxns = transactions.where((t) {
                final d = SpendingAnalyzer.parseDate(t['date']);
                return d != null && d.year == now.year && d.month == now.month;
              }).toList();

              final lastMonthTxns = transactions.where((t) {
                final d = SpendingAnalyzer.parseDate(t['date']);
                if (d == null) return false;
                final lm = now.month == 1 ? 12 : now.month - 1;
                final ly = now.month == 1 ? now.year - 1 : now.year;
                return d.year == ly && d.month == lm;
              }).toList();

              final prediction = ExpensePredictor.predict(
                currentMonthTxns: currentMonthTxns,
                lastMonthTxns: lastMonthTxns,
              );

              List<Insight> insights = ClairvoyanceEngine.generateInsights(
                  currentMonthTxns, lastMonthTxns);

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: tabLabels.asMap().entries.map((e) {
                      bool isSel = _currentIndex == e.key;
                      return Semantics(
                        selected: isSel,
                        button: true,
                        label: e.value,
                        child: GestureDetector(
                          onTap: () => _onTabTapped(e.key),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              children: [
                                Text(e.value,
                                    style: TextStyle(
                                        color: isSel
                                            ? Colors.tealAccent
                                            : AppColors.darkTextSecondary,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 16)),
                                const SizedBox(height: 5),
                                if (isSel)
                                  Container(
                                      height: 2,
                                      width: 20,
                                      color: Colors.tealAccent)
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        KeepAliveView(
                          child: RepaintBoundary(
                            child: PnLTreemapView(
                              expenseData: expenseData,
                              totalExpense: totalExpense,
                            ),
                          ),
                        ),
                        KeepAliveView(
                          child: Column(children: [
                            ClairvoyanceTile(insights: insights),
                            PredictionCard(prediction: prediction),
                            Expanded(
                              child: RepaintBoundary(
                                child: InfiniteTransactionView(
                                    transactions: transactions),
                              ),
                            ),
                          ]),
                        ),
                        KeepAliveView(
                          child: Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: RepaintBoundary(
                                    child: CashflowSankeyView(
                                  income: totalIncome,
                                  savings: (totalIncome > totalExpense)
                                      ? (totalIncome - totalExpense)
                                      : 0.0,
                                  expenses: totalExpense,
                                  topCategories: expenseData,
                                )),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 24.0),
                                child: Semantics(
                                  button: true,
                                  label: 'Launch Financial Wrapped',
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.tealAccent,
                                      foregroundColor: Colors.black,
                                      minimumSize:
                                          const Size(double.infinity, 56),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      elevation: 8,
                                      shadowColor: Colors.tealAccent
                                          .withValues(alpha: 0.4),
                                    ),
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                FinancialStoriesPage(
                                                  totalIncome: totalIncome,
                                                  totalExpenses: totalExpense,
                                                  topCategory: expenseData
                                                          .entries.isNotEmpty
                                                      ? expenseData.entries
                                                          .reduce((a, b) =>
                                                              a.value > b.value
                                                                  ? a
                                                                  : b)
                                                          .key
                                                      : 'None',
                                                  topCategoryAmount: expenseData
                                                          .entries.isNotEmpty
                                                      ? expenseData.entries
                                                          .reduce((a, b) =>
                                                              a.value > b.value
                                                                  ? a
                                                                  : b)
                                                          .value
                                                      : 0.0,
                                                  savingsRate: totalIncome > 0
                                                      ? ((totalIncome >
                                                                  totalExpense)
                                                              ? (totalIncome -
                                                                  totalExpense)
                                                              : 0.0) /
                                                          totalIncome
                                                      : 0.0,
                                                ))),
                                    icon: const Icon(Icons.auto_awesome),
                                    label: const Text('Play Month Wrapped',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        KeepAliveView(
                            child: Center(
                                child: Text(l10n.monthViewSandbox,
                                    style:
                                        const TextStyle(color: Colors.white)))),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class KeepAliveView extends StatefulWidget {
  final Widget child;
  const KeepAliveView({super.key, required this.child});

  @override
  State<KeepAliveView> createState() => _KeepAliveViewState();
}

class _KeepAliveViewState extends State<KeepAliveView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
