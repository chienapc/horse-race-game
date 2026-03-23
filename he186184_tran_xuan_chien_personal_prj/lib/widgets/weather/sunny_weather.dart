import 'package:flutter/material.dart';

class SunnyWeather extends StatelessWidget {
  final double finishLine;

  const SunnyWeather({super.key, required this.finishLine});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(5, (i) {
            return TweenAnimationBuilder(
              tween: Tween(begin: -200.0, end: finishLine + 500),
              duration: Duration(seconds: 40 + i * 5),
              builder: (context, value, child) {
                return Positioned(
                  top: 30.0 + i * 60,
                  left: value,
                  child: const Opacity(
                    opacity: 0.3,
                    child: Text("☁️", style: TextStyle(fontSize: 60)),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}