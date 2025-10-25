import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<IncrementEvent>((event, emit) {
      emit(HomeState(counter: state.counter + 1));
    });
  }
}
