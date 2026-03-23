import 'dart:math';
import 'package:flutter/material.dart';

class RainWeather extends StatefulWidget {
  final double finishLine;

  const RainWeather({super.key, required this.finishLine});

  @override
  State<RainWeather> createState() => _RainWeatherState();
}

class _RainWeatherState extends State<RainWeather>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
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
              children: List.generate(120, (i) {
                double left = _rng.nextDouble() * widget.finishLine;
                double top = (_rng.nextDouble() * 600 +
                    _controller.value * 600) %
                    600;

                return Positioned(
                  left: left,
                  top: top,
                  child: Container(
                    width: 2,
                    height: 15,
                    color: Colors.lightBlueAccent.withOpacity(0.4),
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