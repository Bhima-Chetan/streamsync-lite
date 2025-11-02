import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/video_repository.dart';
import '../../../data/local/database.dart';

// Events
abstract class VideosEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadVideos extends VideosEvent {
  final bool forceRefresh;
  LoadVideos({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class RefreshVideos extends VideosEvent {}

class RetryLoadVideos extends VideosEvent {}

// States
abstract class VideosState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VideosInitial extends VideosState {}

class VideosLoading extends VideosState {
  final bool isRefreshing;
  VideosLoading({this.isRefreshing = false});
  @override
  List<Object?> get props => [isRefreshing];
}

class VideosLoaded extends VideosState {
  final List<Video> videos;
  final bool isRefreshing;

  VideosLoaded(this.videos, {this.isRefreshing = false});

  @override
  List<Object?> get props => [videos, isRefreshing];
}

class VideosError extends VideosState {
  final String message;
  final List<Video>? cachedVideos;

  VideosError(this.message, {this.cachedVideos});

  @override
  List<Object?> get props => [message, cachedVideos];
}

// BLoC
class VideosBloc extends Bloc<VideosEvent, VideosState> {
  final VideoRepository _videoRepository;

  VideosBloc(this._videoRepository) : super(VideosInitial()) {
    on<LoadVideos>(_onLoadVideos);
    on<RefreshVideos>(_onRefreshVideos);
    on<RetryLoadVideos>(_onRetryLoadVideos);
  }

  Future<void> _onLoadVideos(
      LoadVideos event, Emitter<VideosState> emit) async {
    if (state is! VideosLoaded) {
      emit(VideosLoading());
    }

    try {
      final videos = await _videoRepository.getLatestVideos(
        forceRefresh: event.forceRefresh,
      );
      emit(VideosLoaded(videos));
    } catch (e) {
      // Try to get cached data even if network fails
      try {
        final cachedVideos = await _videoRepository.getLatestVideos(
          forceRefresh: false,
        );
        if (cachedVideos.isNotEmpty) {
          emit(VideosError(
            'Failed to load videos: ${e.toString()}',
            cachedVideos: cachedVideos,
          ));
        } else {
          emit(VideosError('Failed to load videos: ${e.toString()}'));
        }
      } catch (_) {
        emit(VideosError('Failed to load videos: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRefreshVideos(
      RefreshVideos event, Emitter<VideosState> emit) async {
    final currentState = state;

    if (currentState is VideosLoaded) {
      emit(VideosLoaded(currentState.videos, isRefreshing: true));
    }

    try {
      final videos = await _videoRepository.getLatestVideos(forceRefresh: true);
      emit(VideosLoaded(videos));
    } catch (e) {
      if (currentState is VideosLoaded) {
        // Keep existing data, just show error
        emit(VideosLoaded(currentState.videos));
        // You could also emit a snackbar event here
      } else {
        emit(VideosError('Failed to refresh: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRetryLoadVideos(
      RetryLoadVideos event, Emitter<VideosState> emit) async {
    add(LoadVideos(forceRefresh: true));
  }
}
