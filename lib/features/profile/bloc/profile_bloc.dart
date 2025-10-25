import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repositories/voluntario_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final VoluntarioRepository voluntarioRepository;

  ProfileBloc(this.voluntarioRepository) : super(ProfileInitial()) {
    on<LoadAptitudesRequested>(_onLoadAptitudesRequested);
    on<CreatePerfilRequested>(_onCreatePerfilRequested);
    on<AsignarAptitudesRequested>(_onAsignarAptitudesRequested);
  }

  Future<void> _onLoadAptitudesRequested(
    LoadAptitudesRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final aptitudes = await voluntarioRepository.getAptitudes();
      emit(AptitudesLoaded(aptitudes));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onCreatePerfilRequested(
    CreatePerfilRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final perfil = await voluntarioRepository.createPerfil(event.request);
      emit(PerfilCreated(perfil));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onAsignarAptitudesRequested(
    AsignarAptitudesRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      await voluntarioRepository.asignarMultiplesAptitudes(
        event.perfilVolId,
        event.aptitudesIds,
      );
      emit(const AptitudesAsignadas('Aptitudes asignadas correctamente'));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
