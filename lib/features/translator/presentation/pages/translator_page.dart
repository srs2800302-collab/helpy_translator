import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/translator_cubit.dart';
import '../cubit/translator_state.dart';
import '../widgets/translation_result_view.dart';

final class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

final class _TranslatorPageState extends State<TranslatorPage> {
  final TextEditingController _controller = TextEditingController(
    text: 'Освободите оборудование от вещей до приезда мастера.',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _translate() {
    FocusScope.of(context).unfocus();
    context.read<TranslatorCubit>().translate(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Helpy Translator'),
      ),
      body: BlocBuilder<TranslatorCubit, TranslatorState>(
        builder: (BuildContext context, TranslatorState state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Каноническая формулировка',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed:
                    state.status == TranslatorStatus.loading ? null : _translate,
                child: state.status == TranslatorStatus.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Перевести'),
              ),
              const SizedBox(height: 16),
              if (state.status == TranslatorStatus.failure)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(state.errorMessage),
                  ),
                ),
              if (state.result != null)
                TranslationResultView(result: state.result!),
            ],
          );
        },
      ),
    );
  }
}
