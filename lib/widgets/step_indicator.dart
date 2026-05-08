import 'package:flutter/material.dart';

class CustomStepIndicator extends StatelessWidget {
  final int current;
  final List<String> steps;
  final Color primary;
  final bool isDark;

  const CustomStepIndicator({
    super.key,
    required this.current,
    required this.steps,
    required this.primary,
    required this.isDark,
  });

  /// 🔥 Get max label width
  double _getMaxLabelWidth() {
    double maxWidth = 0;

    for (final text in steps) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: const TextStyle(fontSize: 10)),
        maxLines: 2,
        textDirection: TextDirection.ltr,
      )..layout();

      if (painter.width > maxWidth) {
        maxWidth = painter.width;
      }
    }

    return maxWidth + 12;
  }

  @override
  Widget build(BuildContext context) {
    final labelWidth = _getMaxLabelWidth();

    /// extra spacing after label
    const extraSpace = 0.0;
    final itemWidth = labelWidth + extraSpace;

    final stepCount = steps.length;
    final totalWidth = itemWidth * stepCount;

    final spacing = totalWidth / (stepCount - 1);

    /// ✅ correct segment logic
    final filledSegments = current.clamp(0, steps.length - 1);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: SizedBox(
          width: totalWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              /// 🔵 BACKGROUND LINE
              Positioned(
                top: 18,
                left: itemWidth / 2,
                right: itemWidth / 2,
                child: Container(
                  height: 2,
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
              ),

              /// 🟢 PROGRESS LINE
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 18,
                left: itemWidth / 2,
                width: itemWidth * filledSegments,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: primary.withOpacity(0.4), blurRadius: 6),
                    ],
                  ),
                ),
              ),

              /// ⚪ STEPS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(stepCount, (index) {
                  final done = current > index;
                  final active = current == index;

                  final bgColor = (done || active)
                      ? primary
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade300);

                  final textColor = (done || active)
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black54);

                  return SizedBox(
                    width: itemWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// 🔵 CIRCLE
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bgColor,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: done
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        /// 🔤 LABEL
                        Text(
                          steps[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: active
                                ? primary
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
