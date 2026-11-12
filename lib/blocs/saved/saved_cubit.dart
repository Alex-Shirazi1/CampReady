import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/campsite.dart';
import '../../repositories/campsite_repository.dart';

part 'saved_state.dart';

class SavedCubit extends Cubit<SavedState> {
  SavedCubit(this.campsiteRepository) : super(const SavedState());

  final CampsiteRepository campsiteRepository;

  Future<void> load(String uid) async {
    emit(state.copyWith(status: SavedStatus.loading));
    try {
      final ids = await campsiteRepository.savedIds(uid);
      emit(SavedState(status: SavedStatus.loaded, ids: ids));
    } catch (_) {
      emit(
        state.copyWith(
          status: SavedStatus.failure,
          error: 'Could not load saved campsites.',
        ),
      );
    }
  }

  void clear() => emit(const SavedState());

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
