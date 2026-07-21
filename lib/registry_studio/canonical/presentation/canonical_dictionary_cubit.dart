import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../application/contracts/canonical_dictionary_loader.dart';
import '../domain/entities/canonical_dictionary.dart';

sealed class CanonicalDictionaryState extends Equatable {
  const CanonicalDictionaryState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CanonicalDictionaryInitial extends CanonicalDictionaryState {
  const CanonicalDictionaryInitial();
}

final class CanonicalDictionaryLoading extends CanonicalDictionaryState {
  const CanonicalDictionaryLoading();
}

final class CanonicalDictionaryLoaded extends CanonicalDictionaryState {
  const CanonicalDictionaryLoaded({required this.dictionary});

  final CanonicalDictionary dictionary;

  @override
  List<Object?> get props => <Object?>[dictionary];
}

final class CanonicalDictionaryFailed extends CanonicalDictionaryState {
  const CanonicalDictionaryFailed({required this.message});

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

final class CanonicalDictionaryCubit extends Cubit<CanonicalDictionaryState> {
  CanonicalDictionaryCubit({required CanonicalDictionaryLoader loader})
    : _loader = loader,
      super(const CanonicalDictionaryInitial());

  final CanonicalDictionaryLoader _loader;

  Future<void> load() async {
    if (state is CanonicalDictionaryLoading) {
      return;
    }

    emit(const CanonicalDictionaryLoading());

    try {
      final CanonicalDictionary dictionary = await _loader.loadDictionary();

      if (isClosed) {
        return;
      }

      emit(CanonicalDictionaryLoaded(dictionary: dictionary));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(CanonicalDictionaryFailed(message: error.toString()));
    }
  }
}
