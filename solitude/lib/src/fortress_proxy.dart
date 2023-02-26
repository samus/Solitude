import 'dart:async';
import 'dart:isolate';
import 'package:solitude/src/fortress.dart';
import 'package:solitude/src/messages/message.dart';
import 'package:solitude/src/messages/query.dart';
import 'package:solitude/src/messages/terminate.dart';

class FortressProxy {
  final _receivePort = ReceivePort();
  final _queryTracker = _QueryTracker();
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

  void sendMessage(Message message) {
    _sendPort?.send(message);
  }

  Future<Response> sendQuery<Response extends QueryResponse>(Query query) {
    final future = _queryTracker.track<Response>(query);
    _sendPort?.send(query);
    return future;
  }

  Future<void> dispose() async {
    _receivePort.close();
    _sendPort?.send(TerminateMessage());
  }

  Future<SendPort> _listen(ReceivePort port) {
    var completer = Completer<SendPort>();
    bool isFirst = true;
    port.listen((message) {
      if (isFirst) {
        completer.complete(message);
        isFirst = false;
        return;
      } else if (message is QueryResponse) {
        _handleQueryResponse(message);
        return;
      }
      print("Proxy received message $message");
    });
    return completer.future;
  }

  void _handleQueryResponse(QueryResponse response) {
    _queryTracker.fulfill(response);
  }
}

class _QueryTracker {
  var messageId = 0;
  final pending = <int, Completer>{};

  Future<Response> track<Response extends QueryResponse>(Query query) {
    query.messageId = ++messageId;
    final completer = Completer<Response>();
    pending[query.messageId] = completer;
    return completer.future;
  }

  void fulfill(QueryResponse response) {
    final completer = pending[response.messageId];
    if (completer == null) {
      return;
    }
    pending.remove(response.messageId);
    completer.complete(response);
  }
}
