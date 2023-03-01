import 'package:solitude/src/messages/query.dart';

import 'message.dart';

abstract class StreamMessage extends Message {
  final int channelId;
  StreamMessage(this.channelId);
}

class StreamInitiateMessage extends StreamMessage {
  final Query query;

  StreamInitiateMessage(super.channelId, this.query);
}

class StreamOnListenMessage extends StreamMessage {
  StreamOnListenMessage(super.channelId);
}

class StreamOnPauseMessage extends StreamMessage {
  StreamOnPauseMessage(super.channelId);
}

class StreamOnResumeMessage extends StreamMessage {
  StreamOnResumeMessage(super.channelId);
}

class StreamOnCancelMessage extends StreamMessage {
  StreamOnCancelMessage(super.channelId);
}
