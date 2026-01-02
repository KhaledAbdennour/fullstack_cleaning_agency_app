import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/cleaning_history_item.dart';
import '../../data/repositories/cleaning_history/cleaning_history_repo.dart';


abstract class CleanerHistoryState {}

class CleanerHistoryInitial extends CleanerHistoryState {}

class CleanerHistoryLoading extends CleanerHistoryState {}

class CleanerHistoryLoaded extends CleanerHistoryState {
  final List<CleaningHistoryItem> items;
  final bool hasMore;
  final int currentPage;
  
  CleanerHistoryLoaded(this.items, {this.hasMore = true, this.currentPage = 1});
}

class CleanerHistoryError extends CleanerHistoryState {
  final String message;
  CleanerHistoryError(this.message);
}

class CleanerHistoryCubit extends Cubit<CleanerHistoryState> {
  final AbstractCleaningHistoryRepo _historyRepo = AbstractCleaningHistoryRepo.getInstance();
  static const int _pageSize = 10;

  CleanerHistoryCubit() : super(CleanerHistoryInitial());

  
  Future<void> loadHistory(int cleanerId, {bool refresh = false}) async {
    if (refresh || state is CleanerHistoryInitial) {
      emit(CleanerHistoryLoading());
    }

    try {
      final page = state is CleanerHistoryLoaded 
          ? (state as CleanerHistoryLoaded).currentPage + 1
          : 1;
      
      final items = await _historyRepo.getCleaningHistoryForCleaner(
        cleanerId,
        page: page,
        limit: _pageSize,
      );

      if (state is CleanerHistoryLoaded && !refresh) {
        final currentState = state as CleanerHistoryLoaded;
        final allItems = [...currentState.items, ...items];
        emit(CleanerHistoryLoaded(
          allItems,
          hasMore: items.length == _pageSize,
          currentPage: page,
        ));
      } else {
        emit(CleanerHistoryLoaded(
          items,
          hasMore: items.length == _pageSize,
          currentPage: page,
        ));
      }
    } catch (e) {
      emit(CleanerHistoryError('Failed to load history: $e'));
    }
  }

  
  Future<void> loadMore(int cleanerId) async {
    if (state is CleanerHistoryLoaded) {
      final currentState = state as CleanerHistoryLoaded;
      if (currentState.hasMore) {
        await loadHistory(cleanerId);
      }
    }
  }

  
  Future<void> refresh(int cleanerId) async {
    await loadHistory(cleanerId, refresh: true);
  }
}




