import 'dart:async';
import 'dart:isolate';
import 'package:solitude/src/fortress.dart';
import 'package:solitude/src/messages/message.dart';
import 'package:solitude/src/messages/query.dart';
import 'package:solitude/src/messages/terminate.dart';
import 'package:solitude/src/streams/stream_proxy_tracker.dart';

class FortressProxy {
  final _receivePort = ReceivePort();
  final _queryTracker = _QueryTracker();
  final _streamTracker = StreamProxyTracker();
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

  /// Send a `Message` to the fortress
  void sendMessage(Message message) {
    _sendPort?.send(message);
  }

  /// Send a `Query` to the fortress and receive the `QueryResponse` in a future.
  Future<Response> sendQuery<Response extends QueryResponse>(Query query) {
    final future = _queryTracker.track<Response>(query);
    _sendPort?.send(query);
    return future;
  }

  /// Send a `Query` to the fortress and receive a stream of `QueryResponses`.
  /// The stream is a standard Dart stream and can be [treated](https://dart.dev/tutorials/language/streams)
  /// as one.  `StreamSubscription` methods such as `pause` and `resume` are
  /// forwarded to the counterpart in the Fortress Isolate.  When the subscription
  /// is canceled the channel between the proxy and the fortress is torn down and
  /// no further interaction with the stream is valid.
  Stream<Response> observeQuery<Response extends QueryResponse>(Query query) {
    return _streamTracker.startTracking<Response>(query, (Message msg) {
      _sendPort?.send(msg);
    });
  }

  /// The proxy must be disposed when finished otherwise the proxied isolate will
  /// not be told to shutdown.  This will cause a program not to terminate properly.
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
