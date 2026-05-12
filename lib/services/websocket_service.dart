import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/app_config.dart';
import 'auth_service.dart';

enum WsConnectionState { disconnected, connecting, connected, reconnecting }

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _intentionalClose = false;
  WsConnectionState _state = WsConnectionState.disconnected;

  final _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<WsConnectionState>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<WsConnectionState> get connectionState => _stateController.stream;
  WsConnectionState get state => _state;

  Future<void> connect(String tripId, String userId) async {
    _intentionalClose = false;
    _setState(WsConnectionState.connecting);

    try {
      final token = await AuthService().getCurrentJwt();
      if (token == null || token.isEmpty) {
        debugPrint('WebSocket: No auth token available');
        return;
      }

      // Construct WebSocket URL
      // Example: wss://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/dev
      final wsUrl = AppConfig.websocketUrl;
      final uri = Uri.parse(
        '$wsUrl?tripId=$tripId&userId=$userId&token=$token',
      );

      _channel = WebSocketChannel.connect(uri);
      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data =
                jsonDecode(message.toString()) as Map<String, dynamic>;
            _messageController.add(data);
          } catch (e) {
            debugPrint('WebSocket parse error: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _scheduleReconnect(tripId, userId);
        },
        onDone: () {
          if (!_intentionalClose) _scheduleReconnect(tripId, userId);
        },
      );

      // Keep-alive ping every 30s
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        sendMessage({'action': 'ping', 'tripId': tripId});
      });
    } catch (e) {
      debugPrint('WebSocket connect error: $e');
      _scheduleReconnect(tripId, userId);
    }
  }

  void sendLocation(double lat, double lng, String tripId) {
    sendMessage({
      'action': 'updateLocation',
      'lat': lat,
      'lng': lng,
      'tripId': tripId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_state == WsConnectionState.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        debugPrint('WebSocket send error: $e');
      }
    }
  }

  void _scheduleReconnect(String tripId, String userId) {
    _setState(WsConnectionState.reconnecting);
    final delays = [1, 2, 4, 8, 16, 30];
    final delayIndex = _reconnectAttempts.clamp(0, delays.length - 1);
    final delay = Duration(seconds: delays[delayIndex]);
    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, () => connect(tripId, userId));
  }

  void _setState(WsConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  void disconnect() {
    _intentionalClose = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _setState(WsConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
  }
}
