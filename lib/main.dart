import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nostr/nostr.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const Lud16HunterApp());
}

class Lud16HunterApp extends StatelessWidget {
  const Lud16HunterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUD16 Hunter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF7931A),
          secondary: Color(0xFF9945FF),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      home: const Lud16HunterScreen(),
    );
  }
}

class Lud16HunterScreen extends StatefulWidget {
  const Lud16HunterScreen({super.key});

  @override
  State<Lud16HunterScreen> createState() => _Lud16HunterScreenState();
}

class _Lud16HunterScreenState extends State<Lud16HunterScreen> {
  final List<String> _foundAddresses = [];
  final Set<String> _seenAddresses = {};
  bool _isHunting = false;
  bool _isComplete = false;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String _status = 'Ready to hunt';
  static const int _targetCount = 21;
  final TextEditingController _relayController = TextEditingController();

  final List<String> _relays = [
    'wss://nos.lol',
    'wss://relay.nostr.band',
    'wss://nostr.wine',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_startHunting);
  }

  @override
  void dispose() {
    _stopHunting();
    _relayController.dispose();
    super.dispose();
  }

  void _showRelaySettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      '📡 RELAY CONFIG',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF7931A),
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _relayController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'wss://relay.example.com',
                          hintStyle: TextStyle(
                            color: Colors.white.withAlpha(77),
                          ),
                          filled: true,
                          fillColor: Colors.white.withAlpha(13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final relay = _relayController.text.trim();
                        if (relay.startsWith('wss://') &&
                            !_relays.contains(relay)) {
                          setState(() => _relays.add(relay));
                          setModalState(() {});
                          _relayController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7931A),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ADD',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _relays.length,
                  itemBuilder: (context, index) {
                    final relay = _relays[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withAlpha(13)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == 0
                                  ? const Color(0xFF00FF88)
                                  : Colors.white.withAlpha(51),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              relay.replaceFirst('wss://', ''),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _relays.length > 1
                                ? () {
                                    setState(() => _relays.removeAt(index));
                                    setModalState(() {});
                                  }
                                : null,
                            icon: Icon(
                              Icons.delete_outline,
                              color: _relays.length > 1
                                  ? const Color(0xFFFF4444)
                                  : Colors.white.withAlpha(26),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startHunting() {
    if (_isHunting) return;

    setState(() {
      _foundAddresses.clear();
      _seenAddresses.clear();
      _isHunting = true;
      _isComplete = false;
      _status = 'Connecting to relay...';
    });

    _connectToRelay(_relays.first);
  }

  void _connectToRelay(String relayUrl) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(relayUrl));
      setState(() => _status = 'Connected to ${relayUrl.split('//').last}');

      final subscriptionId = generate64RandomHexChars().substring(0, 16);
      final request = Request(subscriptionId, [
        Filter(kinds: [0], limit: 500),
      ]);

      _channel!.sink.add(request.serialize());

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          setState(() => _status = 'Error: $error');
          _tryNextRelay(relayUrl);
        },
        onDone: () {
          if (!_isComplete && _foundAddresses.length < _targetCount) {
            _tryNextRelay(relayUrl);
          }
        },
      );
    } catch (e) {
      setState(() => _status = 'Connection failed: $e');
      _tryNextRelay(relayUrl);
    }
  }

  void _tryNextRelay(String currentRelay) {
    final currentIndex = _relays.indexOf(currentRelay);
    if (currentIndex < _relays.length - 1) {
      _channel?.sink.close();
      _subscription?.cancel();
      _connectToRelay(_relays[currentIndex + 1]);
    } else {
      setState(() {
        _isHunting = false;
        _status =
            'All relays exhausted. Found ${_foundAddresses.length} addresses.';
      });
    }
  }

  void _handleMessage(dynamic message) {
    if (_foundAddresses.length >= _targetCount) {
      _completeHunt();
      return;
    }

    try {
      final decoded = jsonDecode(message as String);
      if (decoded is List && decoded.isNotEmpty && decoded[0] == 'EVENT') {
        final eventData = decoded[2] as Map<String, dynamic>;
        final kind = eventData['kind'] as int?;

        if (kind == 0) {
          final content = eventData['content'] as String?;
          if (content != null) {
            _extractLud16(content);
          }
        }
      }
    } catch (e) {
      // Silently ignore parse errors
    }
  }

  void _extractLud16(String content) {
    try {
      final metadata = jsonDecode(content) as Map<String, dynamic>;
      final lud16 = metadata['lud16'] as String?;

      if (lud16 != null &&
          lud16.contains('@') &&
          !_seenAddresses.contains(lud16)) {
        _seenAddresses.add(lud16);
        setState(() {
          _foundAddresses.add(lud16);
          _status = 'Hunting... ${_foundAddresses.length}/$_targetCount';
        });

        if (_foundAddresses.length >= _targetCount) {
          _completeHunt();
        }
      }
    } catch (e) {
      // Invalid JSON in content, skip
    }
  }

  void _completeHunt() {
    setState(() {
      _isHunting = false;
      _isComplete = true;
      _status = '🎯 Hunt complete! Found $_targetCount Lightning addresses';
    });
    _channel?.sink.close();
    _subscription?.cancel();
  }

  void _stopHunting() {
    _channel?.sink.close();
    _subscription?.cancel();
    setState(() {
      _isHunting = false;
      _status = 'Stopped. Found ${_foundAddresses.length} addresses.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A0A2E), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatusBar(),
              Expanded(child: _buildAddressList()),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '⚡',
                      style: TextStyle(
                        fontSize: 32,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFF7931A).withAlpha(128),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'LUD16 HUNTER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Color(0xFFF7931A),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isHunting ? null : _showRelaySettings,
                icon: Icon(
                  Icons.settings,
                  color: _isHunting
                      ? Colors.white.withAlpha(51)
                      : Colors.white54,
                ),
                tooltip: 'Relay Settings',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nostr Kind 0 Lightning Address Scanner',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(153),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isComplete
              ? const Color(0xFF00FF88).withAlpha(77)
              : const Color(0xFFF7931A).withAlpha(51),
        ),
      ),
      child: Row(
        children: [
          if (_isHunting)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FF88),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withAlpha(128),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          Expanded(
            child: Text(
              _status,
              style: TextStyle(
                color: Colors.white.withAlpha(204),
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            '${_foundAddresses.length}/$_targetCount',
            style: const TextStyle(
              color: Color(0xFFF7931A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    if (_foundAddresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🔍',
              style: TextStyle(fontSize: 64, color: Colors.white.withAlpha(51)),
            ),
            const SizedBox(height: 16),
            Text(
              _isHunting
                  ? 'Scanning for Lightning addresses...'
                  : 'Press START to begin hunting',
              style: TextStyle(
                color: Colors.white.withAlpha(102),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _foundAddresses.length,
      itemBuilder: (context, index) {
        final address = _foundAddresses[index];
        final isNew = index >= _foundAddresses.length - 1 && _isHunting;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(20 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isNew
                  ? const Color(0xFFF7931A).withAlpha(26)
                  : Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isNew
                    ? const Color(0xFFF7931A).withAlpha(77)
                    : Colors.white.withAlpha(13),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7931A).withAlpha(51),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFF7931A),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Found: ',
                          style: TextStyle(color: Colors.white.withAlpha(128)),
                        ),
                        TextSpan(
                          text: address,
                          style: const TextStyle(
                            color: Color(0xFF00FF88),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isHunting ? _stopHunting : _startHunting,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHunting
                    ? const Color(0xFFFF4444)
                    : const Color(0xFFF7931A),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isHunting ? 'STOP' : 'START HUNT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
