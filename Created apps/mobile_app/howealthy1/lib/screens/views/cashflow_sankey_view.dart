import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

/// A world-class, animated CustomPainter implementation of a Sankey Diagram
/// designed specifically for personal finance cash flow (Income -> Splitting -> Categories).
class CashflowSankeyView extends StatefulWidget {
  final double income;
  final double savings;
  final double expenses;
  final Map<String, double> topCategories;

  const CashflowSankeyView({
    super.key,
    required this.income,
    required this.savings,
    required this.expenses,
    required this.topCategories,
  });

  @override
  State<CashflowSankeyView> createState() => _CashflowSankeyViewState();
}

class _CashflowSankeyViewState extends State<CashflowSankeyView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _flowAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuint,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.income <= 0) {
      return Center(
        child: Text(
          "Awaiting Income Data",
          style: AppTypography.bodyMedium(isDark: true)
              .copyWith(color: AppColors.darkTextSecondary),
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _flowAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: _SankeyPainter(
              income: widget.income,
              savings: widget.savings,
              expenses: widget.expenses,
              topCategories: widget.topCategories,
              progress: _flowAnimation.value,
            ),
            size: const Size(double.infinity, 300),
          );
        },
      ),
    );
  }
}

class _SankeyPainter extends CustomPainter {
  final double income;
  final double savings;
  final double expenses;
  final Map<String, double> topCategories;
  final double progress;

  _SankeyPainter({
    required this.income,
    required this.savings,
    required this.expenses,
    required this.topCategories,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We construct a 3-layer Sankey
    // Layer 1: Income (Left)
    // Layer 2: Savings vs Expenses (Middle)
    // Layer 3: Top Categories (Right)

    const double nodeWidth = 12.0;

    // Column x-coordinates
    const double col1X = 0;
    final double col2X = size.width * 0.45;
    final double col3X = size.width - nodeWidth;

    // Define vertical space scale based on income height
    final double maxH = size.height;
    final double incomeScale = maxH / (income > 0 ? income : 1);

    // -- Layer 1 Coordinates --
    final double incSize = income * incomeScale;
    final Rect incRect =
        Rect.fromLTWH(col1X, (maxH - incSize) / 2, nodeWidth, incSize);

    // -- Layer 2 Coordinates --
    final double savSize = savings * incomeScale;
    final double expSize = expenses * incomeScale;
    const double gap2 = 30.0;
    // Center Layer 2 vertically
    final double l2TotalH = savSize + expSize + gap2;
    final double l2StartY = (maxH - l2TotalH) / 2;

    final Rect savRect = Rect.fromLTWH(col2X, l2StartY, nodeWidth, savSize);
    final Rect expRect =
        Rect.fromLTWH(col2X, savRect.bottom + gap2, nodeWidth, expSize);

    // -- Layer 3 Coordinates (Expense breakdown) --
    // Only map categories up to total expenses
    // Only map categories up to total expenses
    const double gap3 = 10.0;

    // If we have categories, we align them vertically to center of expenses
    double totalCatsSize =
        topCategories.values.fold(0.0, (a, b) => a + (b * incomeScale));
    int catCount = topCategories.length;
    double l3TotalH =
        totalCatsSize + (gap3 * (catCount - 1 > 0 ? catCount - 1 : 0));
    double l3StartY = expRect.center.dy - (l3TotalH / 2);
    // ensure within bounds
    if (l3StartY < 0) l3StartY = 0;

    // Draw Links first so they are under nodes

    // Link 1: Income -> Savings
    _drawSankeyLink(
      canvas: canvas,
      startRect: incRect,
      startOffsetY: 0,
      endRect: savRect,
      height: savSize,
      color: AppColors.savings.withValues(alpha: 0.3 * progress),
      progress: progress,
    );

    // Link 2: Income -> Expenses
    _drawSankeyLink(
      canvas: canvas,
      startRect: incRect,
      startOffsetY: savSize, // Exits right below savings
      endRect: expRect,
      height: expSize,
      color: AppColors.expense.withValues(alpha: 0.3 * progress),
      progress: progress,
    );

    // Link 3: Expenses -> Categories
    double expExitY = 0;
    double catStartY = l3StartY;

    for (var entry in topCategories.entries) {
      final double catNodeSize = entry.value * incomeScale;
      final Rect catRect =
          Rect.fromLTWH(col3X, catStartY, nodeWidth, catNodeSize);

      final Color catColor = AppColors.forCategory(entry.key);

      _drawSankeyLink(
        canvas: canvas,
        startRect: expRect,
        startOffsetY: expExitY,
        endRect: catRect,
        height: catNodeSize,
        color: catColor.withValues(alpha: 0.3 * progress),
        progress: progress,
      );

      // Draw Node
      _drawNode(canvas, catRect, catColor, progress);
      _drawLabel(
        canvas: canvas,
        text: entry.key,
        amount: entry.value,
        x: col3X - 8,
        y: catRect.center.dy,
        alignRight: true,
      );

      expExitY += catNodeSize;
      catStartY += catNodeSize + gap3;
    }

    // Draw Nodes (Layer 1 & 2)
    _drawNode(canvas, incRect, AppColors.income, progress);
    _drawLabel(
      canvas: canvas,
      text: "Income",
      amount: income,
      x: col1X + nodeWidth + 8,
      y: incRect.top - 12,
      alignRight: false,
    );

    _drawNode(canvas, savRect, AppColors.savings, progress);
    _drawLabel(
      canvas: canvas,
      text: "Savings & Inv.",
      amount: savings,
      x: col2X + nodeWidth + 8,
      y: savRect.center.dy,
      alignRight: false,
    );

    _drawNode(canvas, expRect, AppColors.expense, progress);
    _drawLabel(
      canvas: canvas,
      text: "Expenses",
      amount: expenses,
      x: col2X + nodeWidth + 8,
      y: expRect.center.dy,
      alignRight: false,
    );
  }

  void _drawNode(Canvas canvas, Rect rect, Color color, double progress) {
    if (rect.height <= 0) return;

    // Scale node vertically for entrance animation
    final double animH = rect.height * progress;
    final Rect animRect = Rect.fromLTWH(
      rect.left,
      rect.top + (rect.height - animH) / 2, // Grow from center
      rect.width,
      animH,
    );

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(animRect, const Radius.circular(6)),
      paint,
    );
  }

  void _drawSankeyLink({
    required Canvas canvas,
    required Rect startRect,
    required double startOffsetY,
    required Rect endRect,
    required double height,
    required Color color,
    required double progress,
  }) {
    if (height <= 0 || progress <= 0.05) return;

    final double startX = startRect.right;
    final double startY = startRect.top + startOffsetY;
    final double endX = endRect.left;
    final double endY = endRect.top;

    // Use cubic bezier for fluid ribbon flow
    final Path path = Path();
    final double controlDist = (endX - startX) * 0.5;

    // Animate the path drawing left to right
    final double currentEndX = startX + ((endX - startX) * progress);

    // Interpolate Y if it's partially drawn (to keep the curve feeling connected to an invisible leading edge)
    final double currentEndY = startY + ((endY - startY) * progress);
    final double currentControlDist = controlDist * progress;

    path.moveTo(startX, startY);
    path.cubicTo(
      startX + currentControlDist,
      startY,
      currentEndX - currentControlDist,
      currentEndY,
      currentEndX,
      currentEndY,
    );
    path.lineTo(currentEndX, currentEndY + height);
    path.cubicTo(
      currentEndX - currentControlDist,
      currentEndY + height,
      startX + currentControlDist,
      startY + height,
      startX,
      startY + height,
    );
    path.close();

    final Paint linkPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, linkPaint);
  }

  void _drawLabel({
    required Canvas canvas,
    required String text,
    required double amount,
    required double x,
    required double y,
    required bool alignRight,
  }) {
    if (progress < 0.6) return; // Delay text appearance
    // Fade in text
    final double textOpacity = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);

    final currencyFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final TextPainter tpName = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTypography.bodySmall(isDark: true).copyWith(
          color: AppColors.darkTextSecondary.withValues(alpha: textOpacity),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    tpName.layout();

    final TextPainter tpAmt = TextPainter(
      text: TextSpan(
        text: currencyFmt.format(amount),
        style: AppTypography.bodySmall(isDark: true).copyWith(
          color: AppColors.darkTextPrimary.withValues(alpha: textOpacity),
          fontSize: 10,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    tpAmt.layout();

    final double drawX = alignRight ? x - tpName.width : x;
    final double amtDrawX = alignRight ? x - tpAmt.width : x;

    // Center vertically around Y
    tpName.paint(canvas, Offset(drawX, y - (tpName.height)));
    tpAmt.paint(canvas, Offset(amtDrawX, y + 2));
  }

  @override
  bool shouldRepaint(covariant _SankeyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.income != income ||
        oldDelegate.savings != savings ||
        oldDelegate.expenses != expenses;
  }
}
