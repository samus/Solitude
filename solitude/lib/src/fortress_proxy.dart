import 'dart:async';
import 'dart:isolate';
import 'package:solitude/src/fortress.dart';
import 'package:solitude/src/messages/command.dart';
import 'package:solitude/src/messages/terminate.dart';

class FortressProxy {
  final _receivePort = ReceivePort();
  SendPort? _sendPort;

  /// Start up an isolated fortress. `fortressMain` will be called in the
  /// spawned isolate's startup sequence. `fortressMain` can access classes
  /// declared in the program but does not share any data with it.
  Future<void> start(
      {required void Function(Fortress fortress) fortressMain}) async {
    await Isolate.spawn(
      (SendPort sendPort) async {
        /// This runs in the spawned isolate.
        final fortress = Fortress(sendPort);
        fortressMain(fortress);
        await fortress.listen();
        Isolate.exit();
      },
      _receivePort.sendPort,
    );
    _sendPort = await _listen(_receivePort);
  }

  void sendCommand(Command command) {
    _sendPort?.send(command);
  }

  Future<SendPort> _listen(ReceivePort port) {
    var completer = Completer<SendPort>();
    bool isFirst = true;
    port.listen((message) {
      if (isFirst) {
        completer.complete(message);
        isFirst = false;
        return;
      }
      print("Proxy received message $message");
    });
    return completer.future;
  }

  Future<void> dispose() async {
    _receivePort.close();
    _sendPort?.send(TerminateMessage());
  }
}
