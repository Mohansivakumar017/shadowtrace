import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/sos_service.dart';
import '../services/location_service.dart';

class VoiceCommandScreen extends StatefulWidget {
  const VoiceCommandScreen({Key? key}) : super(key: key);

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  late stt.SpeechToText _speechToText;
  final SosService _sosService = SosService();
  final LocationService _locationService = LocationService();

  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _speechToText = stt.SpeechToText();
      _initializeSpeech();
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speechToText.initialize(
        onError: (error) => debugPrint('Error: $error'),
        onStatus: (status) => debugPrint('Status: $status'),
      );
    } catch (e) {
      debugPrint('Initialize speech error: $e');
    }
  }

  void _startListening() async {
    if (!_isListening) {
      if (await _speechToText.initialize()) {
        setState(() => _isListening = true);

        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;

              if (result.finalResult) {
                _processCommand(result.recognizedWords);
              }
            });
          },
          localeId: 'en_US',
        );
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      if (!kIsWeb) {
        _speechToText.stop();
      }
      setState(() => _isListening = false);
    }
  }

  void _processCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('help') ||
        lowerCommand.contains('sos') ||
        lowerCommand.contains('emergency') ||
        lowerCommand.contains('danger')) {
      _triggerVoiceSOS();
    }
  }

  Future<void> _triggerVoiceSOS() async {
    final location = _locationService.getLastKnownPosition();
    if (location != null) {
      await _sosService.triggerVoiceSOS(
        'user-default',
        tripId: null,
        lat: location.latitude,
        lng: location.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice SOS triggered'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _speechToText.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Voice Commands'),
        ),
        body: const Center(
          child: Text('Voice commands are not available on web platform'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Commands'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onLongPress: _startListening,
                    onLongPressUp: _stopListening,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.red : Colors.blue,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.red : Colors.blue)
                                .withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isListening ? 'Listening...' : 'Hold to speak',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (_recognizedText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last recognized:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_recognizedText),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Recognized commands:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• "help" - Trigger SOS'),
                    Text('• "SOS" - Trigger SOS'),
                    Text('• "emergency" - Trigger SOS'),
                    Text('• "danger" - Trigger SOS'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

