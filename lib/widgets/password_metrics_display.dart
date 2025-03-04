import 'package:flutter/material.dart';

class PasswordMetricsDisplay extends StatelessWidget {
  final Map<String, String> metrics;

  const PasswordMetricsDisplay({Key? key, required this.metrics})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var entry in metrics.entries)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${entry.key}: ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  TextSpan(
                    text: entry.value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
