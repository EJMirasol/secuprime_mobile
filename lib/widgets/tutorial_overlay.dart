import 'package:flutter/material.dart';

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final int initialStep;
  final Function(int)? onStepChanged;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.initialStep = 0,
    this.onStepChanged,
  });

  @override
  _TutorialOverlayState createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep;

  _TutorialOverlayState() : _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
        widget.onStepChanged?.call(_currentStep);
      });
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];

    return Stack(
      children: [
        if (step.isFullScreen)
          Positioned.fill(
            child: Container(
              color: const Color.fromARGB(255, 24, 24, 24).withOpacity(0.6),
            ),
          ),
        Positioned(
          left: step.targetRect.left,
          top: step.targetRect.top,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _controller.value * 10),
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_downward,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191647),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    step.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: _nextStep,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class TutorialStep {
  final Rect targetRect;
  final String description;
  final bool isFullScreen;

  TutorialStep({
    required this.targetRect,
    required this.description,
    this.isFullScreen = false,
  });
}
