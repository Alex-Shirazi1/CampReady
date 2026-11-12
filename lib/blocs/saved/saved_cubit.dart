import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/campsite.dart';
import '../../repositories/campsite_repository.dart';

part 'saved_state.dart';

class SavedCubit extends Cubit<SavedState> {
  SavedCubit(this.campsiteRepository) : super(const SavedState());

  final CampsiteRepository campsiteRepository;
  int _loadVersion = 0;

  Future<void> load(String uid) async {
    final version = ++_loadVersion;
    emit(state.copyWith(status: SavedStatus.loading));
    try {
      final ids = await campsiteRepository.savedIds(uid);
      if (version != _loadVersion) return;
      emit(SavedState(status: SavedStatus.loaded, ids: ids));
    } catch (_) {
      if (version != _loadVersion) return;
      emit(
        state.copyWith(
          status: SavedStatus.failure,
          error: 'Could not load saved campsites.',
        ),
      );
    }
  }

  void clear() {
    _loadVersion++;
    emit(const SavedState());
  }

  /// Updates the list only after Firestore confirms the write.
  Future<void> save(String uid, Campsite site) async {
    await campsiteRepository.save(uid, site);
    emit(state.copyWith(ids: {...state.ids, site.id}));
  }

  Future<void> remove(String uid, Campsite site) async {
    await campsiteRepository.remove(uid, site);
    emit(state.copyWith(ids: {...state.ids}..remove(site.id)));
  }
}
