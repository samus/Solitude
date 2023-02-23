import 'dart:isolate';

import 'package:solitude/src/handlers/handler.dart';
import 'package:solitude/src/messages/command.dart';
import 'package:solitude/src/messages/terminate.dart';

class Fortress {
  final SendPort _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  final _hanldlers = <Type, Handler>{};

  Fortress(this._sendPort) {
    _sendPort.send(_receivePort.sendPort);
  }

  Future<void> listen() async {
    await for (final message in _receivePort) {
      if (message is TerminateMessage) {
        break;
      }
      if (message is Command) {
        _handleCommand(message);
        continue;
      }
      print("Fortress received an unrecognized message $message");
      _sendPort.send("Got it");
    }
    _receivePort.close();
  }

  void registerHandler<T extends Command>(Handler<T> handler) {
    _hanldlers[T] = handler;
  }

  void _handleCommand(Command cmd) {
    final handler = _hanldlers[cmd.runtimeType];
    if (handler == null) {
      print("No handler found for command $cmd");
      return;
    }
    handler.execute(cmd);
  }
}
