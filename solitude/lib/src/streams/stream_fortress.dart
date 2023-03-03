import 'dart:async';

import 'package:solitude/src/messages/message.dart';
import 'package:solitude/src/messages/query.dart';
import 'package:solitude/src/messages/stream.dart';

class StreamFortress<Response extends QueryResponse> {
  final int channelId;
  final Stream<Response> stream;
  final void Function(Message) send;

  StreamSubscription<Response>? _subscription;

  StreamFortress(
      {required this.channelId, required this.stream, required this.send});

  void handleControlMessage(StreamMessage message) {
    if (message is StreamOnListenMessage) {
      _handleOnListen();
    } else if (message is StreamOnPauseMessage) {
      _handleOnPause();
    } else if (message is StreamOnResumeMessage) {
      _handleOnResume();
    } else if (message is StreamOnCancelMessage) {
      _handleOnCancel();
    }
  }

  void _handleOnListen() {
    _subscription = stream.listen((response) {
      final msg = StreamResponseMessage(channelId, response);
      send(msg);
    });
  }

  void _handleOnPause() {
    _subscription?.pause();
  }

  void _handleOnResume() {
    _subscription?.resume();
  }

  void _handleOnCancel() {
    _subscription?.cancel();
  }
}
