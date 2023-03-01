import 'package:solitude/src/messages/message.dart';
import 'package:solitude/src/messages/query.dart';
import 'package:solitude/src/messages/stream.dart';
import 'package:solitude/src/streams/stream_proxy.dart';

class StreamProxyTracker {
  var _channelId = 0;
  final proxies = <int, StreamProxy>{};

  Stream<Response> startTracking<Response extends QueryResponse>(
      Query query, Null Function(Message msg) send) {
    final id = ++_channelId;
    final proxy = StreamProxy<Response>(
      channelId: id,
      send: send,
      onCancel: (channelId) => proxies.remove(channelId),
    );
    proxies[id] = proxy;
    send(StreamInitiateMessage(id, query));
    return proxy.stream;
  }
}
