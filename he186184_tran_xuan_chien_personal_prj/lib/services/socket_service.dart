import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'dart:io';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  IO.Socket? _socket;

  String? currentUrl;

  // IP của PC làm máy chủ
  static String get defaultServerUrl {
    return 'http://10.33.71.183:3000';
  }

  void connect({String? url, required Function onConnect, required Function onConnectError}) {
    String finalUrl = url != null && url.isNotEmpty ? url : defaultServerUrl;

    if (_socket != null) {
      if (_socket!.connected && currentUrl == finalUrl) {
         onConnect(); // Gọi lại ngay để tiếp tục flow join
         return;
      }
      _socket!.disconnect();
      _socket = null;
    }

    currentUrl = finalUrl;

    _socket = IO.io(finalUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Connected to socket server');
      onConnect();
    });

    _socket!.onConnectError((err) {
      debugPrint('Socket connection error: $err');
      onConnectError(err);
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from socket server');
    });
  }

  void joinRoom({required String roomId, required String nickname, required Function(dynamic) onJoined}) {
    emitEvent('join_room', {'roomId': roomId, 'nickname': nickname});
    onEvent('room_joined', onJoined);
  }

  void emitEvent(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    }
  }

  void onEvent(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, (data) => callback(data));
    }
  }

  void offEvent(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }

  bool get isConnected => _socket?.connected ?? false;

  String? get socketId => _socket?.id;
}
