import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:he186184_tran_xuan_chien_personal_prj/screens/horse_race_screen.dart';
import 'package:he186184_tran_xuan_chien_personal_prj/services/socket_service.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final SocketService _socketService = SocketService();

  bool _isLoading = false;
  bool _inRoom = false;
  String _role = 'Client';
  List<dynamic> _players = [];
  String _roomId = '';
  String _nickname = '';

  @override
  void initState() {
    super.initState();
  }

  void _setupSocketEvents() {
    _socketService.offEvent('update_player_list');
    _socketService.offEvent('room_joined');
    _socketService.offEvent('navigate_to_race');
    _socketService.offEvent('room_full');

    _socketService.onEvent('update_player_list', (data) {
      if (mounted) {
        setState(() {
          _players = data ?? [];
          
          if (_inRoom) {
            // Tự động thăng bậc lên Host nếu Chủ phòng cũ đã thoát
            for (var p in _players) {
              if (p['name'] == _nickname) {
                _role = p['isHost'] == true ? 'Host' : 'Client';
                break;
              }
            }
          }
        });
      }
    });

    _socketService.onEvent('room_joined', (data) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _inRoom = true;
          _role = data['role'] ?? 'Client';
        });
      }
    });

    _socketService.onEvent('room_full', (data) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Phòng đã đầy!")),
        );
      }
    });

    _socketService.onEvent('navigate_to_race', (data) {
      if(mounted && _inRoom) {
        _navigateToRace();
      }
    });
  }

  void _joinRoom() {
    if (_nicknameController.text.isEmpty || _roomIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập Tên và Mã Phòng!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _roomId = _roomIdController.text;
      _nickname = _nicknameController.text;
    });

    String url = _ipController.text.trim();
    if (url.isNotEmpty && !url.startsWith('http')) {
      url = 'http://$url:3000';
    }

    _socketService.connect(
      url: url.isNotEmpty ? url : null,
      onConnect: () {
        debugPrint("Socket connected!");
        _setupSocketEvents();
        _socketService.emitEvent(
          'join_room',
          {'roomId': _roomId, 'nickname': _nickname}
        );
      },
      onConnectError: (err) {
        debugPrint("Socket error: $err");
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối server. Vui lòng kiểm tra IP!")));
           setState(() => _isLoading = false);
        }
      }
    );
  }

  void _startRaceSession() {
    if (_role == 'Host') {
       _socketService.emitEvent('start_session', {'roomId': _roomId});
    }
  }

  void _navigateToRace() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HorseRaceScreen(
          role: _role,
          roomId: _roomId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _roomIdController.dispose();
    _ipController.dispose();
    _socketService.offEvent('update_player_list');
    _socketService.offEvent('room_joined');
    _socketService.offEvent('navigate_to_race');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_inRoom) {
          _socketService.emitEvent('leave_room', {'roomId': _roomId});
          setState(() {
            _inRoom = false;
            _isLoading = false;
            _players = [];
            _role = 'Client';
          });
        } else {
          _socketService.disconnect();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background Tet theme
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.0,
                  colors: [Colors.red.shade600, Colors.red.shade900, Colors.black],
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeInDown(
                          child: Text(
                            "ĐẠI HỘI ĐUA NGỰA",
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.yellow.shade100,
                              shadows: [Shadow(color: Colors.orange.shade900, offset: const Offset(3, 3))],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 50),

                        if (!_inRoom) _buildJoinForm() else _buildRoomLobby(),

                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 15,
              left: 15,
              child: SafeArea(
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_inRoom) {
                        _socketService.emitEvent('leave_room', {'roomId': _roomId});
                        setState(() {
                          _inRoom = false;
                          _isLoading = false;
                          _players = [];
                          _role = 'Client';
                        });
                      } else {
                        _socketService.disconnect();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinForm() {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.yellowAccent, width: 2),
        ),
        child: Column(
          children: [
            _buildTextField("Tên của bạn", _nicknameController, Icons.person),
            const SizedBox(height: 15),
            _buildTextField("Mã phòng (VD: 9999)", _roomIdController, Icons.meeting_room),
            const SizedBox(height: 15),
            _buildTextField("IP (VD: 192.168.1.1)", _ipController, Icons.wifi),
            const SizedBox(height: 30),

            _isLoading
              ? const CircularProgressIndicator(color: Colors.yellowAccent)
              : ElevatedButton(
                  onPressed: _joinRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    side: const BorderSide(color: Colors.yellowAccent, width: 2),
                  ),
                  child: const Text(
                    "VÀO PHÒNG",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))]
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomLobby() {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.yellowAccent, width: 2),
        ),
        child: Column(
          children: [
            Text(
              "PHÒNG: $_roomId",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.yellowAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Vai trò: ${_role == 'Host' ? 'Chủ phòng 👑' : 'Người chơi'}",
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 20),

            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  final isMe = player['name'] == _nickname;
                  final isHost = player['isHost'] == true;

                  return ListTile(
                    leading: Text(isHost ? "👑" : "🏇", style: const TextStyle(fontSize: 24)),
                    title: Text(
                      player['name'] ?? 'Unknown',
                      style: TextStyle(
                        color: isMe ? Colors.yellowAccent : Colors.white,
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isMe ? const Text("(Bạn)", style: TextStyle(color: Colors.white54)) : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            if (_role == 'Host')
              ElevatedButton(
                onPressed: _startRaceSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  side: const BorderSide(color: Colors.white, width: 2),
                ),
                child: const Text(
                  "BẮT ĐẦU ĐUA",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black, offset: Offset(1, 1))]
                  ),
                ),
              )
            else
              const Text(
                "Đang chờ chủ phòng bắt đầu...",
                style: TextStyle(color: Colors.yellowAccent, fontStyle: FontStyle.italic),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.yellowAccent),
        filled: true,
        fillColor: Colors.black38,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
