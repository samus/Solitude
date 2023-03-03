import 'package:solitude/src/messages/message.dart';
import 'package:solitude/src/messages/query.dart';

abstract class Handler<MessageType extends Message> {
  void handle(MessageType message);
}

mixin RespondingHandler<MessageType extends Message> on Handler<MessageType> {
  void handleWithResponse(
      MessageType message, void Function(QueryResponse response) respond);

  @override
  void handle(MessageType message) {}
}

mixin StreamingHandler<MessageType extends Message> on Handler<MessageType> {
  Stream<QueryResponse> open(MessageType message);

  @override
  void handle(MessageType message) {}
}
