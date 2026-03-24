import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:animate_do/animate_do.dart';
import 'package:he186184_tran_xuan_chien_personal_prj/providers/race_history_provider.dart';
import 'package:provider/provider.dart';
import 'package:he186184_tran_xuan_chien_personal_prj/widgets/weather/weather_layer.dart';
import 'package:he186184_tran_xuan_chien_personal_prj/services/socket_service.dart';

class HorseRaceScreen extends StatefulWidget {
  final String? role;
  final String? roomId;
  const HorseRaceScreen({super.key, this.role, this.roomId});

  @override
  State<HorseRaceScreen> createState() => _HorseRaceScreenState();
}

class _HorseRaceScreenState extends State<HorseRaceScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final Ticker _ticker;
  WeatherType _weather = WeatherType.sunny;
  final Random _rng = Random();
  Duration _lastElapsed = Duration.zero;

  // Cấu hình
  final int _horseCount = 6;
  late List<ValueNotifier<double>> _horseNotifiers;
  late List<double> _horseSpeeds;
  late List<double> _targetSpeeds;

  // Tiền tệ & Cược
  int _diamonds = 1000;
  int _betAmount = 100;
  int _selectedHorse = 0;
  bool _isRacing = false;
  bool _raceFinished = false;

  int _totalPot = 0;
  bool _hasBet = false;
  List<dynamic> _roomPlayers = [];

  List<int> _finishOrder = [];
  final double _finishLine = 5000.0;

  bool _showCountdown = false;
  String _countdownText = "";

  final SocketService _socketService = SocketService();
  bool get _isHost => widget.role == 'Host' || widget.role == null;

  @override
  void initState() {
    super.initState();
    _horseNotifiers = List.generate(_horseCount, (_) => ValueNotifier(0.0));
    _horseSpeeds = List.generate(_horseCount, (_) => 0.0);
    _targetSpeeds = List.generate(_horseCount, (_) => 0.0);
    _weather = WeatherType
        .values[_rng.nextInt(WeatherType.values.length)];

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _ticker = createTicker(_onTick);

    if (widget.roomId != null) {
      _socketService.onEvent('update_pos', (data) {
        if (!_isHost && mounted) {
           List<dynamic> pos = data; // 'data' is already the array of positions sent by server
           for (int i=0; i<_horseCount; i++) {
               if (pos.length > i) {
                 _horseNotifiers[i].value = (pos[i] as num).toDouble();
               }
           }
        }
      });
      _socketService.onEvent('start_countdown', (data) {
        if (!_isHost && mounted) {
           _executeStartSequence();
        }
      });
      _socketService.onEvent('finish_race', (data) {
         if (!_isHost && mounted) {
            List<dynamic> order = data['finishOrder'];
            _finishOrder = order.map((e) => e as int).toList();
            _finishRaceLocally();
         }
      });
      _socketService.onEvent('reset_race', (data) {
         if (!_isHost && mounted) {
            _resetRaceLocally();
         }
      });
      _socketService.onEvent('update_pot', (data) {
        if (mounted) {
          setState(() {
            _totalPot = data['totalPot'] ?? 0;
            _roomPlayers = data['players'] ?? [];
          });
        }
      });
    }
  }

  void dispose() {
    if (widget.roomId != null) {
      _socketService.offEvent('update_pos');
      _socketService.offEvent('start_countdown');
      _socketService.offEvent('finish_race');
      _socketService.offEvent('reset_race');
      _socketService.offEvent('update_pot');
    }
    _ticker.dispose();
    _scrollController.dispose();
    for (var n in _horseNotifiers) n.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _resetRaceLocally() {
    _weather = WeatherType
        .values[_rng.nextInt(WeatherType.values.length)];
    for (var n in _horseNotifiers) n.value = 0.0;
    for (int i = 0; i < _horseCount; i++) {
      _horseSpeeds[i] = 0;
      _targetSpeeds[i] = 100 + _rng.nextDouble() * 150;
    }
    _finishOrder = [];
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() {
      _raceFinished = false;
      _hasBet = false;
      if (widget.roomId == null) _totalPot = 0;
    });
  }

  void _resetRace() {
    if (_isHost && widget.roomId != null) {
      _socketService.emitEvent('reset_race', {'roomId': widget.roomId});
    }
    _resetRaceLocally();
  }

  void _placeBet() {
    if (_diamonds < _betAmount || _isRacing || _hasBet) return;
    setState(() {
      _diamonds -= _betAmount;
      _hasBet = true;
    });
    if (widget.roomId != null) {
      _socketService.emitEvent('place_bet', {
        'roomId': widget.roomId,
        'betAmount': _betAmount,
        'horseIndex': _selectedHorse
      });
    } else {
      setState(() {
        _totalPot = _betAmount;
      });
    }
  }

  Future<void> _startRace() async {
    if (_isRacing) return;
    
    // Only host can start multiplayer race if in room
    if (widget.roomId != null && !_isHost) return;

    if (_isHost && widget.roomId != null) {
       _socketService.emitEvent('start_countdown', {'roomId': widget.roomId});
    }
    
    _executeStartSequence();
  }

  Future<void> _executeStartSequence() async {

    setState(() {
      _isRacing = true;
      _raceFinished = false;
      _showCountdown = true;
    });

    _resetRaceLocally();

    List<String> seq = ["3", "2", "1", "CHẠY!"];
    for (var s in seq) {
      setState(() => _countdownText = s);
      await Future.delayed(const Duration(seconds: 1));
    }

    setState(() => _showCountdown = false);
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  int _getCurrentRank(int horseIndex) {
    List<double> positions = _horseNotifiers.map((n) => n.value).toList();
    List<double> sortedPositions = List.from(positions)..sort((a, b) => b.compareTo(a));
    return sortedPositions.indexOf(positions[horseIndex]) + 1;
  }

  void _onTick(Duration elapsed) {
    if (_isHost) {
      final double dt = (elapsed - _lastElapsed).inMilliseconds / 1000;
      _lastElapsed = elapsed;

      for (int i = 0; i < _horseCount; i++) {
        if (_horseNotifiers[i].value >= _finishLine) continue;

        if (elapsed.inMilliseconds % 1200 < 30) {
          _targetSpeeds[i] = 120 + _rng.nextDouble() * 180;
          if (_rng.nextDouble() < 0.05) _targetSpeeds[i] = 400;
        }

        _horseSpeeds[i] = lerpDouble(_horseSpeeds[i], _targetSpeeds[i], dt * 0.7)!;
        _horseNotifiers[i].value += _horseSpeeds[i] * dt;

        if (_horseNotifiers[i].value >= _finishLine && !_finishOrder.contains(i)) {
          _finishOrder.add(i);
        }
      }

      if (widget.roomId != null && elapsed.inMilliseconds % 50 < 30) {
         _socketService.emitEvent('send_pos', {
            'room': widget.roomId,
            'positions': _horseNotifiers.map((n) => n.value).toList()
         });
      }

      if (_finishOrder.length == _horseCount) {
         _finishRaceLocally();
         if (widget.roomId != null) {
            _socketService.emitEvent('finish_race', {
               'roomId': widget.roomId,
               'finishOrder': _finishOrder
            });
         }
      }
    } else {
      _lastElapsed = elapsed;
    }

    double targetHorsePos = _horseNotifiers[_selectedHorse].value;
    if (_scrollController.hasClients && targetHorsePos > 250) {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double scrollPos = min(targetHorsePos - 250, maxScroll);
      _scrollController.jumpTo(scrollPos);
    }
  }

  void _finishRaceLocally() {
    _ticker.stop();
    int winAmount = 0;
    int rank = _finishOrder.indexOf(_selectedHorse) + 1;
    String title = "";
    String subtitle = "";

    if (widget.roomId != null) {
      List<int> bettedHorses = [];
      for (var p in _roomPlayers) {
        if (p['selectedHorse'] != null) {
          bettedHorses.add(p['selectedHorse'] as int);
        }
      }
      int bestRank = 999;
      int winningHorse = -1;
      for (int horse in bettedHorses) {
        int r = _finishOrder.indexOf(horse) + 1;
        if (r > 0 && r < bestRank) {
          bestRank = r;
          winningHorse = horse;
        }
      }
      if (winningHorse == -1) {
        title = "HÒA";
        subtitle = "Không ai đặt cược!";
      } else {
        bool isWinner = (_selectedHorse == winningHorse);
        int totalBetOnWinningHorse = 0;
        for (var p in _roomPlayers) {
          if (p['selectedHorse'] == winningHorse && p['betAmount'] != null) {
            totalBetOnWinningHorse += (p['betAmount'] as num).toInt();
          }
        }

        if (isWinner && totalBetOnWinningHorse > 0) {
          double proportion = min(1.0, _betAmount / totalBetOnWinningHorse);
          winAmount = (_totalPot * proportion).toInt();
          title = "CHIẾN THẮNG! 🏆";
          subtitle = "Ngựa số ${winningHorse + 1} có hạng cao nhất trong phòng ($bestRank)\nBạn ăn ${(proportion * 100).toInt()}% Hũ theo tỷ lệ cược";
        } else {
          title = "THUA CUỘC 💀";
          subtitle = "Ngựa số ${winningHorse + 1} thắng vì có hạng cao nhất phòng ($bestRank)";
        }
      }
    } else {
      if (rank == 1) winAmount = (_betAmount * 3).toInt();
      else if (rank == 2) winAmount = (_betAmount * 2).toInt();
      else if (rank == 3) winAmount = (_betAmount * 1.5).toInt();
      title = rank <= 3 ? "CHIẾN THẮNG! 🏆" : "THUA CUỘC 💀";
      subtitle = "Ngựa của bạn đứng hạng: $rank";
    }

    setState(() {
      _diamonds += winAmount;
      _isRacing = false;
      _raceFinished = true;
      if (_diamonds <= 0) {
        _betAmount = 0;
      } else if (_betAmount > _diamonds) {
        _betAmount = _diamonds >= 10 ? 10 : _diamonds;
      }
      if (_diamonds >= 10 && _betAmount < 10) _betAmount = 10;
    });

    _showResultDialog(title, subtitle, winAmount);

    final record = RaceRecord(
      date: DateTime.now(),
      selectedHorse: _selectedHorse,
      finishOrder: List.from(_finishOrder),
      betAmount: _betAmount,
      winAmount: winAmount > 0 ? winAmount : -_betAmount,
    );
    context.read<RaceHistoryProvider>().addRecord(record);
  }

  void _showResultDialog(String title, String subtitle, int win) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text(title, style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1,1))]))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1,1))])),
            const SizedBox(height: 10),
            Text(win > 0 ? "+ $win 🧧" : "- $_betAmount 🧧",
                style: TextStyle(color: win > 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1,1))])),
          ],
        ),
        actions: [Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("TIẾP TỤC", style: TextStyle(fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1,1))]))))],
      ),
    );
  }

  double? lerpDouble(double a, double b, double t) => a + (b - a) * t;

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _socketService.disconnect();
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [



          // LỚP 1: ĐƯỜNG ĐUA
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Container(
              width: _finishLine + screenWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade900, Colors.green.shade700, Colors.green.shade900],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(

                children: [

                  for (int i = 0; i <= _horseCount; i++)
                    Positioned(
                      top: 25.0 + (i * 55.0) - 5,
                      left: 0,
                      right: 0,
                      child: Container(height: 2, color: Colors.white10),
                    ),

                  for (double d = 0; d <= _finishLine; d += 200)
                    Positioned(
                      left: d,
                      top: 20,
                      bottom: 20,
                      child: Container(width: 1, color: Colors.white24),
                    ),

                  Positioned(
                      left: _finishLine,
                      top: 0,
                      bottom: 0,
                      child: Container(
                          width: 80,
                          color: Colors.white24,
                          child: const Center(child: Text("🏁", style: TextStyle(fontSize: 40)))
                      )
                  ),

                  for (int i = 0; i < _horseCount; i++)
                    ValueListenableBuilder<double>(
                      valueListenable: _horseNotifiers[i],
                      builder: (context, pos, _) {
                        int currentRank = _getCurrentRank(i);
                        return Positioned(
                          left: pos,
                          top: 25.0 + (i * 55.0),
                          child: _HorseWithUI(
                              index: i,
                              isSelected: _selectedHorse == i,
                              rank: currentRank,
                              horseColor: _getHorseColor(i),
                              isRacing: _isRacing && pos < _finishLine
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // UI TRẠNG THÁI
          Positioned(
            top: 20, right: 20,
            child: Row(
              children: [
                if (_totalPot > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(color: Colors.red.shade900.withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.yellowAccent)),
                    child: Text("💰 HŨ: $_totalPot", style: const TextStyle(color: Colors.yellowAccent, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))])),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.cyanAccent)),
                  child: Text("🧧 $_diamonds", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))])),
                ),
              ],
            ),
          ),

          if (_isRacing) _buildMinimap(screenWidth),

          if (!_isRacing && !_showCountdown) _buildRightBettingSlider(),

          if (!_isRacing && !_showCountdown)
            Positioned(bottom: 20, left: 100, right: 120, child: _buildHorseSelector()),

          if (_showCountdown)
            Container(color: Colors.black45, child: Center(child: FadeInScale(child: Text(_countdownText, style: const TextStyle(fontSize: 100, color: Colors.yellowAccent, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2))]))))),

          // NÚT CHƠI LẠI
          if (_raceFinished && !_isRacing)
            Center(
              child: ZoomIn(
                child: ElevatedButton.icon(
                  onPressed: _resetRace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  icon: const Icon(Icons.replay_rounded, weight: 700),
                  label: const Text("CHƠI LẠI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))])),
                ),
              ),
            ),

          Positioned(top: 15, left: 15, child: SafeArea(child: CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () {
            _socketService.disconnect();
            Navigator.pop(context);
          })))),
        ],
      ),
     ),
    );
  }

  Widget _buildRightBettingSlider() {
    const Color goldBase = Color(0xFFFFC107);
    // Kiểm tra xem người chơi còn đủ tiền cược tối thiểu (10) không
    final bool hasMoney = _diamonds >= 10;

    return Positioned(
      right: 20,
      top: 80,
      bottom: 80,
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
              color: hasMoney ? goldBase.withOpacity(0.8) : Colors.redAccent.withOpacity(0.5),
              width: 2
          ),
        ),
        child: Column(
          children: [
            // Icon trạng thái
            Icon(
                hasMoney ? Icons.add_circle_outline : Icons.error_outline,
                color: hasMoney ? goldBase : Colors.redAccent,
                size: 28
            ),

            Expanded(
              child: Opacity(
                opacity: hasMoney && !_hasBet && !_isRacing ? 1.0 : 0.5,
                child: IgnorePointer(
                  ignoring: !hasMoney || _hasBet || _isRacing,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6,
                      activeTrackColor: goldBase,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: hasMoney ? Colors.white : Colors.grey,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    ),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: _betAmount.toDouble().clamp(0, _diamonds > 0 ? _diamonds.toDouble() : 10),
                        min: 0,
                        // Logic max an toàn để không bao giờ bị lỗi min <= max
                        max: _diamonds > 0 ? _diamonds.toDouble() : 10,
                        onChanged: (val) {
                          if (hasMoney && !_hasBet && !_isRacing) setState(() => _betAmount = val.toInt());
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Hiển thị số tiền cược hoặc cảnh báo
            Text(
                hasMoney ? "$_betAmount" : "HẾT",
                style: TextStyle(
                  color: hasMoney ? goldBase : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: const [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))]
                )
            ),
            Text(
                hasMoney ? "CƯỢC" : "TIỀN",
                style: TextStyle(
                  color: hasMoney ? Colors.white70 : Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))]
                )
            ),

            // Nút bấm "Xin Lộc" nhanh nếu hết tiền (Tùy chọn thêm)
            if (!hasMoney)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: IconButton(
                  icon: const Icon(Icons.gif_box, color: Colors.yellowAccent),
                  onPressed: () {
                    setState(() => _diamonds = 500); // Tặng 500 khi hết tiền
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lì xì đầu năm 500🧧!"), backgroundColor: Colors.red),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorseSelector() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text("ĐẶT CỬA:", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))])),
          for (int i = 0; i < _horseCount; i++)
            GestureDetector(
              onTap: () {
                if (!_hasBet && !_isRacing) setState(() => _selectedHorse = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedHorse == i ? _getHorseColor(i) : Colors.white10,
                  border: _selectedHorse == i ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: const Text("🏇", style: TextStyle(fontSize: 24)),
              ),
            ),
          const SizedBox(width: 5),
          if (_hasBet && !_isHost)
            const Text("Đang chờ Host bắt đầu...", style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))]))
          else
            ElevatedButton(
              onPressed: () {
                 if (!_hasBet) _placeBet();
                 else if (_isHost) _startRace();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12)
              ),
              child: Text(
                 !_hasBet ? "ĐẶT CƯỢC" : "CHẠY",
                 style: const TextStyle(fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))])
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimap(double screenWidth) {
    double minimapWidth = screenWidth * 0.4;
    return Positioned(
      top: 15, left: screenWidth * 0.3,
      child: Container(
        width: minimapWidth, height: 40,
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              right: 15,
              top: 5,
              bottom: 5,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 5)
                    ]
                ),
              ),
            ),
            for (int i = 0; i < _horseCount; i++)
              ValueListenableBuilder<double>(
                valueListenable: _horseNotifiers[i],
                builder: (context, pos, _) => Positioned(
                  left: 10 + (pos / _finishLine) * (minimapWidth - 40),
                  child: Transform.translate(offset: Offset(0, (i - 2.5) * 5), child: Text("🏇", style: TextStyle(fontSize: 10, color: _getHorseColor(i)))),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getHorseColor(int i) {
    List<Color> colors = [Colors.redAccent, Colors.orangeAccent, Colors.yellowAccent, Colors.greenAccent, Colors.cyanAccent, Colors.purpleAccent];
    return colors[i];
  }
}

class _HorseWithUI extends StatelessWidget {
  final int index;
  final bool isSelected;
  final int rank;
  final bool isRacing;
  final Color horseColor;

  const _HorseWithUI({
    required this.index,
    required this.isSelected,
    required this.rank,
    required this.isRacing,
    required this.horseColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isSelected)
          FadeInDown(
            animate: true,
            from: 10,
            child: const Icon(Icons.arrow_drop_down, color: Colors.yellowAccent, size: 30),
          )
        else
          const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: horseColor.withOpacity(0.5), width: 1),
          ),
          child: Text(
            "$rank",
            style: TextStyle(
                color: horseColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: const [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))]
            ),
          ),
        ),

        if (isRacing)
          _JumpingAnimation(child: _HorseIcon(index: index))
        else
          _HorseIcon(index: index),

        Container(
          width: 45, height: 6,
          decoration: const BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.all(Radius.elliptical(45, 6))),
        ),
      ],
    );
  }
}

class _HorseIcon extends StatelessWidget {
  final int index;
  const _HorseIcon({required this.index});
  @override
  Widget build(BuildContext context) {
    return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateY(pi),
        child: const Text("🏇", style: TextStyle(fontSize: 45))
    );
  }
}

class _JumpingAnimation extends StatefulWidget {
  final Widget child;
  const _JumpingAnimation({required this.child});
  @override
  State<_JumpingAnimation> createState() => _JumpingAnimationState();
}

class _JumpingAnimationState extends State<_JumpingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150))..repeat(reverse: true); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) => Transform.translate(offset: Offset(0, -_controller.value * 8), child: child), child: widget.child);
  }
}

class FadeInScale extends StatelessWidget {
  final Widget child;
  const FadeInScale({required this.child, super.key});
  @override
  Widget build(BuildContext context) { return FadeIn(duration: const Duration(milliseconds: 500), child: ZoomIn(child: child)); }
}