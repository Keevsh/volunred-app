import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volunred_app/core/models/aptitud.dart';
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
      // Cargar todas las aptitudes disponibles
      final aptitudes = await voluntarioRepository.getAptitudes();
      
      // Si hay un perfilVolId, cargar también las aptitudes ya asignadas
      List<Aptitud> aptitudesAsignadas = [];
      if (event.perfilVolId != null) {
        try {
          aptitudesAsignadas = await voluntarioRepository.getAptitudesByVoluntario(event.perfilVolId!);
        } catch (e) {
          // Si hay error al obtener las aptitudes asignadas, continuar sin ellas
          print('⚠️ No se pudieron cargar las aptitudes asignadas: $e');
        }
      }
      
      emit(AptitudesLoaded(aptitudes, aptitudesAsignadas: aptitudesAsignadas));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onCreatePerfilRequested(
    CreatePerfilRequested event,
    Emitter<ProfileState> emit,
  ) async {
    print('🔄 Iniciando creación de perfil...');
    emit(ProfileLoading());

    try {
      print('📤 Enviando request al repositorio: ${event.request.toJson()}');
      final perfil = await voluntarioRepository.createPerfil(event.request);
      print('✅ Perfil creado exitosamente: ${perfil.toJson()}');
      emit(PerfilCreated(perfil));
    } catch (e, stackTrace) {
      print('❌ Error en _onCreatePerfilRequested: $e');
      print('❌ StackTrace: $stackTrace');
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
