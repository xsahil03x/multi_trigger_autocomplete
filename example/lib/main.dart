import 'package:flutter/material.dart';
import 'package:multi_trigger_autocomplete/multi_trigger_autocomplete.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.teal,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  final mentionData = const [
    'Sahil',
    'Avni',
    'Trapti',
    'Gaurav',
    'Prateek',
    'Amit',
    'Ayush',
    'Shubham',
  ];

  final hashtagData = const [
    'love',
    'instagood',
    'photooftheday',
    'fashion',
    'beautiful',
    'happy',
    'cute',
    'tbt',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi Trigger Autocomplete'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: MultiTriggerAutocomplete(
          debounceDuration: Duration.zero,
          autocompleteTriggers: [
            AutocompleteTrigger(
              trigger: '@',
              optionsViewBuilder: (_, query, controller, closeOptions) {
                return OptionsView(
                  data: mentionData,
                  controller: controller,
                  autocompleteQuery: query,
                  closeOptions: closeOptions,
                );
              },
            ),
            AutocompleteTrigger(
              trigger: '#',
              optionsViewBuilder: (_, query, controller, closeOptions) {
                return OptionsView(
                  data: hashtagData,
                  controller: controller,
                  autocompleteQuery: query,
                  closeOptions: closeOptions,
                );
              },
            ),
          ],
          fieldViewBuilder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Write something...',
              ),
            );
          },
        ),
      ),
    );
  }
}

class OptionsView<T extends Object> extends StatelessWidget {
  const OptionsView({
    super.key,
    required this.data,
    required this.autocompleteQuery,
    required this.controller,
    required this.closeOptions,
  });

  final Iterable<T> data;
  final AutocompleteQuery autocompleteQuery;
  final TextEditingController controller;
  final VoidCallback closeOptions;

  @override
  Widget build(BuildContext context) {
    final options = data.where((it) {
      final normalizedOption = it.toString().toLowerCase();
      final normalizedQuery = autocompleteQuery.query.toLowerCase();
      return normalizedOption.contains(normalizedQuery);
    });

    if (options.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      // color: _streamChatTheme.colorTheme.barsBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            dense: true,
            horizontalTitleGap: 0,
            title: Text('Matching Options...'),
          ),
          const Divider(height: 0),
          LimitedBox(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, i) {
                final option = options.elementAt(i);
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text(option.toString()[0]),
                  ),
                  title: Text(option.toString()),
                  onTap: () {
                    final text = controller.text;
                    final querySelection = autocompleteQuery.selection;

                    final queryEndsWithSpace =
                        text.substring(querySelection.end).startsWith(' ');

                    final newText = text.substring(0, querySelection.start) +
                        option.toString() +
                        (queryEndsWithSpace ? '' : ' ') +
                        text.substring(querySelection.end);

                    final newCursorPosition =
                        querySelection.start + option.toString().length + 1;

                    controller.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: newCursorPosition,
                      ),
                    );

                    closeOptions();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
