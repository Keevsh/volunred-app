import 'package:equatable/equatable.dart';
import '../../../core/models/dto/request_models.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadAptitudesRequested extends ProfileEvent {}

class CreatePerfilRequested extends ProfileEvent {
  final CreatePerfilVoluntarioRequest request;

  const CreatePerfilRequested(this.request);

  @override
  List<Object?> get props => [request];
}

class AsignarAptitudesRequested extends ProfileEvent {
  final int perfilVolId;
  final List<int> aptitudesIds;

  const AsignarAptitudesRequested(this.perfilVolId, this.aptitudesIds);

  @override
  List<Object?> get props => [perfilVolId, aptitudesIds];
}
