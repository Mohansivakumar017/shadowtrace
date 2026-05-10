import 'package:flutter/material.dart';
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
  final SOSService _sosService = SOSService();
  final LocationService _locationService = LocationService();

  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speechToText.initialize(
        onError: (error) => print('Error: $error'),
        onStatus: (status) => print('Status: $status'),
      );
    } catch (e) {
      print('Initialize speech error: $e');
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
      _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  void _processCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('help') || lowerCommand.contains('sos') ||
        lowerCommand.contains('emergency') || lowerCommand.contains('danger')) {
      _triggerVoiceSOS();
    }
  }

  Future<void> _triggerVoiceSOS() async {
    final location = _locationService.getLastKnownPosition();
    if (location != null) {
      await _sosService.triggerSOS(location.latitude, location.longitude);

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
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                            color: (_isListening ? Colors.red : Colors.blue).withOpacity(0.5),
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
                    const Text('Last recognized:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Text('Recognized commands:', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Command')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _listening ? 180 : 140,
              height: _listening ? 180 : 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _listening ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(_listening ? 0.35 : 0.08), blurRadius: 32)],
              ),
              child: const Icon(Icons.mic, size: 56),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_recognized, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _toggleListen, child: Text(_listening ? 'Stop Listening' : 'Start Listening')),
          ],
        ),
      ),
    );
  }
}
