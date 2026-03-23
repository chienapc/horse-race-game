import 'dart:math';
import 'package:flutter/material.dart';

class SakuraWeather extends StatefulWidget {
  final double finishLine;

  const SakuraWeather({super.key, required this.finishLine});

  @override
  State<SakuraWeather> createState() => _SakuraWeatherState();
}

class _SakuraWeatherState extends State<SakuraWeather>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: List.generate(40, (i) {
                double startX = _rng.nextDouble() * widget.finishLine;
                double progress = (_controller.value * 600);

                return Positioned(
                  left: startX + sin(progress / 50) * 20,
                  top: progress % 600,
                  child: const Opacity(
                    opacity: 0.7,
                    child: Text("🌸", style: TextStyle(fontSize: 20)),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}