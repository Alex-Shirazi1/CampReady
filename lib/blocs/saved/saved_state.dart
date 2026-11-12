part of 'saved_cubit.dart';

enum SavedStatus { initial, loading, loaded, failure }

class SavedState extends Equatable {
  const SavedState({
    this.status = SavedStatus.initial,
    this.ids = const {},
    this.error,
  });

  final SavedStatus status;
  final Set<String> ids;
  final String? error;

  bool contains(String siteId) => ids.contains(siteId);

  SavedState copyWith({SavedStatus? status, Set<String>? ids, String? error}) =>
      SavedState(
        status: status ?? this.status,
        ids: ids ?? this.ids,
        error: error,
      );

  @override
  List<Object?> get props => [status, ids, error];
}
