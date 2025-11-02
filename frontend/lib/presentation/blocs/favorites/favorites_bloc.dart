import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/local/database.dart';

// Events
abstract class FavoritesEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {
  final String userId;
  LoadFavorites(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ToggleFavorite extends FavoritesEvent {
  final String userId;
  final String videoId;

  ToggleFavorite(this.userId, this.videoId);

  @override
  List<Object?> get props => [userId, videoId];
}

class RefreshFavorites extends FavoritesEvent {
  final String userId;
  RefreshFavorites(this.userId);
  @override
  List<Object?> get props => [userId];
}

// States
abstract class FavoritesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<Video> favoriteVideos;
  final Set<String> favoriteVideoIds;

  FavoritesLoaded(this.favoriteVideos, this.favoriteVideoIds);

  bool isFavorite(String videoId) => favoriteVideoIds.contains(videoId);

  @override
  List<Object?> get props => [favoriteVideos, favoriteVideoIds];
}

class FavoritesError extends FavoritesState {
  final String message;
  FavoritesError(this.message);
  @override
  List<Object?> get props => [message];
}

class FavoriteToggling extends FavoritesState {
  final List<Video> favoriteVideos;
  final Set<String> favoriteVideoIds;
  final String togglingVideoId;

  FavoriteToggling(
    this.favoriteVideos,
    this.favoriteVideoIds,
    this.togglingVideoId,
  );

  @override
  List<Object?> get props =>
      [favoriteVideos, favoriteVideoIds, togglingVideoId];
}

// BLoC
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final AppDatabase _database;

  FavoritesBloc(this._database) : super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<RefreshFavorites>(_onRefreshFavorites);
  }

  Future<void> _onLoadFavorites(
      LoadFavorites event, Emitter<FavoritesState> emit) async {
    emit(FavoritesLoading());

    try {
      // Get favorite video IDs
      final favoriteRecords = await (_database.select(_database.favorites)
            ..where((f) => f.userId.equals(event.userId)))
          .get();

      final favoriteVideoIds = favoriteRecords.map((f) => f.videoId).toSet();

      // Get the actual video data
      final videos = await (_database.select(_database.videos)
            ..where((v) => v.videoId.isIn(favoriteVideoIds.toList())))
          .get();

      emit(FavoritesLoaded(videos, favoriteVideoIds));
    } catch (e) {
      emit(FavoritesError('Failed to load favorites: ${e.toString()}'));
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<FavoritesState> emit) async {
    final currentState = state;

    if (currentState is FavoritesLoaded) {
      emit(FavoriteToggling(
        currentState.favoriteVideos,
        currentState.favoriteVideoIds,
        event.videoId,
      ));
    }

    try {
      final isFavorite = currentState is FavoritesLoaded
          ? currentState.isFavorite(event.videoId)
          : false;

      if (isFavorite) {
        // Remove from favorites
        await (_database.delete(_database.favorites)
              ..where((f) => f.id.equals('${event.userId}-${event.videoId}')))
            .go();
      } else {
        // Add to favorites
        await _database.into(_database.favorites).insert(
              FavoritesCompanion.insert(
                id: '${event.userId}-${event.videoId}',
                userId: event.userId,
                videoId: event.videoId,
              ),
            );
      }

      // Try to sync with backend
      try {
        // TODO: Implement toggleFavorite in repository when backend is ready
        // await _videoRepository.toggleFavorite(event.userId, event.videoId);
      } catch (e) {
        // Will sync later
        print('Failed to sync favorite: $e');
      }

      // Reload favorites
      add(LoadFavorites(event.userId));
    } catch (e) {
      if (currentState is FavoritesLoaded) {
        emit(FavoritesLoaded(
          currentState.favoriteVideos,
          currentState.favoriteVideoIds,
        ));
      } else {
        emit(FavoritesError('Failed to toggle favorite: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRefreshFavorites(
      RefreshFavorites event, Emitter<FavoritesState> emit) async {
    add(LoadFavorites(event.userId));
  }
}
