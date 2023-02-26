abstract class Message {}

mixin Identifiable on Message {
  int messageId = -1;
}
