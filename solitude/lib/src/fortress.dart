import 'dart:isolate';

import 'package:solitude/src/handlers/handler.dart';
import 'package:solitude/src/messages/message.dart';
import 'package:solitude/src/messages/query.dart';
import 'package:solitude/src/messages/stream.dart';
import 'package:solitude/src/messages/terminate.dart';
import 'package:solitude/src/streams/stream_fortress_tracker.dart';

class Fortress {
  final SendPort _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  final _streamTracker = StreamFortressTracker();

  final _hanldlers = <Type, Handler>{};

  Fortress(this._sendPort) {
    _sendPort.send(_receivePort.sendPort);
  }

  Future<void> listen() async {
    await for (final message in _receivePort) {
      if (message is TerminateMessage) {
        break;
      }
      if (message is StreamInitiateMessage) {
        _handleStreamInitiateMessage(message);
      } else if (message is StreamMessage) {
        _streamTracker.handleResponse(message);
      } else if (message is Message) {
        _handleMessage(message);
      } else {
        print("Fortress received an unrecognized message $message");
      }
    }
    _receivePort.close();
  }

  void registerHandler<T extends Message>(Handler<T> handler) {
    _hanldlers[T] = handler;
  }

  void _handleMessage(Message msg) {
    final handler = _hanldlers[msg.runtimeType];
    if (handler == null) {
      print("No handler found for command $msg");
      return;
    }
    if (msg is Identifiable && handler is RespondingHandler) {
      handler.handleWithResponse(msg, (response) {
        response.messageId = msg.messageId;
        _sendResponse(response);
      });
    } else {
      handler.handle(msg);
    }
  }

  void _handleStreamInitiateMessage(StreamInitiateMessage msg) {
    final handler = _hanldlers[msg.query.runtimeType];
    if (handler is! StreamingHandler) {
      return;
    }
    final stream = handler.open(msg.query);
    _streamTracker.startTracking(msg.channelId, stream, (message) {
      _sendPort.send(message);
    });
  }

  void _sendResponse(QueryResponse response) {
    _sendPort.send(response);
  }
}
