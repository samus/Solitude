import 'package:solitude/src/messages/message.dart';
import 'package:solitude/src/messages/query.dart';
import 'package:solitude/src/messages/stream.dart';
import 'package:solitude/src/streams/stream_fortress.dart';

class StreamFortressTracker {
  final _streamsFortresses = <int, StreamFortress>{};

  void startTracking<Response extends QueryResponse>(int channelId,
      Stream<Response> stream, void Function(Message message) send) {
    final fort = StreamFortress(
      channelId: channelId,
      stream: stream,
      send: send,
    );
    _streamsFortresses[channelId] = fort;
  }

  void handleResponse(StreamMessage message) {
    final fort = _streamsFortresses[message.channelId];
    fort?.handleControlMessage(message);

    if (message is StreamOnCancelMessage) {
      _streamsFortresses.remove(message.channelId);
    }
  }
}
