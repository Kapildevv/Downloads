import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'package:intl/intl.dart';

/// A premium, immersive "Wrapped" style story view for the user's financial recap.
class FinancialStoriesPage extends StatefulWidget {
  final double totalIncome;
  final double totalExpenses;
  final String topCategory;
  final double topCategoryAmount;
  final double savingsRate;

  const FinancialStoriesPage({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.savingsRate,
  });

  @override
  State<FinancialStoriesPage> createState() => _FinancialStoriesPageState();
}

class _FinancialStoriesPageState extends State<FinancialStoriesPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  final int _totalStories = 4;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // 5 seconds per story
    )..addListener(() {
        setState(() {});
      });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < _totalStories - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context); // Close at the end
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0),
      child: Row(
        children: List.generate(_totalStories, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: index < _currentIndex
                      ? 1.0
                      : (index == _currentIndex
                          ? _progressController.value
                          : 0.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.compactCurrency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isPositive = widget.totalIncome > widget.totalExpenses;

    final stories = [
      // Story 1: Intro / Cash flow
      _StorySlide(
        gradient: AppColors.darkCardGradient,
        icon: Icons.auto_awesome,
        title: "Your Month in Review",
        subtitle: "Let's look at the numbers.",
        mainDigit: isPositive ? "Positive Cashflow 🚀" : "Over Budget 🚨",
      ),
      // Story 2: Income
      _StorySlide(
        gradient: AppColors.incomeGradient,
        icon: Icons.arrow_downward_rounded,
        title: "Total Inflow",
        subtitle: "The money that entered your ecosystem.",
        mainDigit: currencyFmt.format(widget.totalIncome),
      ),
      // Story 3: Top Expense
      _StorySlide(
        gradient: AppColors.expenseGradient,
        icon: Icons.local_fire_department_rounded,
        title: "Biggest Burn Rate",
        subtitle: "You spent the most on ${widget.topCategory}.",
        mainDigit: currencyFmt.format(widget.topCategoryAmount),
      ),
      // Story 4: Savings Rate
      _StorySlide(
        gradient: AppColors.premiumGradient,
        icon: Icons.savings_rounded,
        title: "Savings Rate",
        subtitle: "Building the empire.",
        mainDigit: "${(widget.savingsRate * 100).toStringAsFixed(1)}%",
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width * 0.3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        onLongPressDown: (_) => _progressController.stop(),
        onLongPressEnd: (_) => _progressController.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: stories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _resetProgress();
              },
              itemBuilder: (context, index) {
                return stories[index];
              },
            ),
            // Progress indicators at top
            Align(
              alignment: Alignment.topCenter,
              child: _buildProgressBar(),
            ),
            // Close button
            Positioned(
              top: 70,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorySlide extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String mainDigit;

  const _StorySlide({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.mainDigit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 60),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: AppTypography.displayMedium(isDark: true).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTypography.bodyLarge(isDark: true).copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AnimatedScale(
            scale: 1.0,
            duration: const Duration(seconds: 1),
            child: Text(
              mainDigit,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -2,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
