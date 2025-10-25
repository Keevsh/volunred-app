import 'package:equatable/equatable.dart';
import '../../../core/models/aptitud.dart';
import '../../../core/models/perfil_voluntario.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class AptitudesLoaded extends ProfileState {
  final List<Aptitud> aptitudes;

  const AptitudesLoaded(this.aptitudes);

  @override
  List<Object?> get props => [aptitudes];
}

class PerfilCreated extends ProfileState {
  final PerfilVoluntario perfil;

  const PerfilCreated(this.perfil);

  @override
  List<Object?> get props => [perfil];
}

class AptitudesAsignadas extends ProfileState {
  final String message;

  const AptitudesAsignadas(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
