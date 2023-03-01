import 'dart:async';

import 'package:solitude/src/messages/message.dart';
import 'package:solitude/src/messages/stream.dart';

class StreamProxy<Response> {
  final int channelId;
  final void Function(Message) send;
  final void Function(int channelId) onCancel;
  late StreamController<Response> _controller;

  StreamProxy(
      {required this.channelId, required this.send, required this.onCancel}) {
    _controller = StreamController(
        onListen: _onListen,
        onCancel: _onCancel,
        onPause: _onPause,
        onResume: _onResume);
  }

  Stream<Response> get stream {
    return _controller.stream;
  }

  void receive(Response response) {
    if (!_controller.hasListener ||
        _controller.isPaused ||
        _controller.isClosed) {
      return;
    }
    _controller.add(response);
  }

  void _onListen() {
    send(StreamOnListenMessage(channelId));
  }

  void _onPause() {
    send(StreamOnPauseMessage(channelId));
  }

  void _onResume() {
    send(StreamOnResumeMessage(channelId));
  }

  void _onCancel() {
    send(StreamOnCancelMessage(channelId));
    onCancel(channelId);
  }
}
