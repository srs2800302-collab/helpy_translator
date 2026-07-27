import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'translator_access_key_store.dart';

enum TranslatorAccessKeyFailure { restore, save, delete }

final class TranslatorAccessKeyState extends Equatable {
  const TranslatorAccessKeyState({
    required this.isRestoring,
    required this.accessKey,
    this.failure,
  });

  const TranslatorAccessKeyState.initial()
    : this(isRestoring: true, accessKey: '');

  final bool isRestoring;
  final String accessKey;
  final TranslatorAccessKeyFailure? failure;

  TranslatorAccessKeyState copyWith({
    bool? isRestoring,
    String? accessKey,
    TranslatorAccessKeyFailure? failure,
    bool clearFailure = false,
  }) {
    return TranslatorAccessKeyState(
      isRestoring: isRestoring ?? this.isRestoring,
      accessKey: accessKey ?? this.accessKey,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => <Object?>[isRestoring, accessKey, failure];
}

final class TranslatorAccessKeyCubit extends Cubit<TranslatorAccessKeyState> {
  TranslatorAccessKeyCubit({required this.store})
    : super(const TranslatorAccessKeyState.initial());

  final TranslatorAccessKeyStore store;

  Future<void> restore() async {
    try {
      final String? restored = await store.load();
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isRestoring: false,
          accessKey: restored ?? '',
          clearFailure: true,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isRestoring: false,
          failure: TranslatorAccessKeyFailure.restore,
        ),
      );
    }
  }

  Future<void> save(String accessKey) async {
    if (isClosed) {
      return;
    }

    emit(state.copyWith(accessKey: accessKey));

    try {
      if (accessKey.isEmpty) {
        await store.clear();
      } else {
        await store.save(accessKey);
      }

      if (isClosed) {
        return;
      }

      emit(state.copyWith(clearFailure: true));
    } catch (_) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(failure: TranslatorAccessKeyFailure.save));
    }
  }

  Future<void> delete() async {
    try {
      await store.clear();
      if (isClosed) {
        return;
      }

      emit(state.copyWith(accessKey: '', clearFailure: true));
    } catch (_) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(failure: TranslatorAccessKeyFailure.delete));
    }
  }
}
