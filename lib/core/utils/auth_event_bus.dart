import 'dart:async';

enum AuthEvent { tokenExpired, loggedOut }

class AuthEventBus {
  static final AuthEventBus instance = AuthEventBus._internal();
  AuthEventBus._internal();

  final _controller = StreamController<AuthEvent>.broadcast();

  Stream<AuthEvent> get stream => _controller.stream;

  void add(AuthEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
