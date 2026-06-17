import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class BottomNavEvent {}

class TabChanged extends BottomNavEvent {
  final int tabIndex;
  TabChanged(this.tabIndex);
}

// States
class BottomNavState {
  final int currentIndex;
  const BottomNavState({required this.currentIndex});
}

// Bloc
class BottomNavBloc extends Bloc<BottomNavEvent, BottomNavState> {
  BottomNavBloc() : super(const BottomNavState(currentIndex: 0)) {
    on<TabChanged>((event, emit) {
      emit(BottomNavState(currentIndex: event.tabIndex));
    });
  }
}

