import 'package:flutter/material.dart';
import 'sunny_weather.dart';
import 'rain_weather.dart';
import 'fog_weather.dart';
import 'sakura_weather.dart';

enum WeatherType { sunny, rain, fog, sakura }

class WeatherLayer extends StatelessWidget {
  final WeatherType weather;
  final double finishLine;

  const WeatherLayer({
    super.key,
    required this.weather,
    required this.finishLine,
  });

  @override
  Widget build(BuildContext context) {
    switch (weather) {
      case WeatherType.sunny:
        return SunnyWeather(finishLine: finishLine);
      case WeatherType.rain:
        return RainWeather(finishLine: finishLine);
      case WeatherType.fog:
        return const FogWeather();
      case WeatherType.sakura:
        return SakuraWeather(finishLine: finishLine);
    }
  }
}