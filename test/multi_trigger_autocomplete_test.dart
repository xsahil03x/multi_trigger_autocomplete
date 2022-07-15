import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multi_trigger_autocomplete/multi_trigger_autocomplete.dart';

void main() {
  testWidgets('should render fine', (tester) async {
    const multiTriggerAutocompleteKey = Key('multiTriggerAutocomplete');
    const multiTriggerAutocomplete = Boilerplate(
      child: MultiTriggerAutocomplete(
        key: multiTriggerAutocompleteKey,
        autocompleteTriggers: [],
      ),
    );

    await tester.pumpWidget(multiTriggerAutocomplete);

    expect(find.byKey(multiTriggerAutocompleteKey), findsOneWidget);
  });

  testWidgets(
    'should render fine if both `textEditingController` and `focusNode` is provided',
    (tester) async {
      const multiTriggerAutocompleteKey = Key('multiTriggerAutocomplete');
      final multiTriggerAutocomplete = Boilerplate(
        child: MultiTriggerAutocomplete(
          key: multiTriggerAutocompleteKey,
          autocompleteTriggers: const [],
          textEditingController: TextEditingController(),
          focusNode: FocusNode(),
        ),
      );

      await tester.pumpWidget(multiTriggerAutocomplete);

      expect(find.byKey(multiTriggerAutocompleteKey), findsOneWidget);
    },
  );

  testWidgets(
    "should throw assertion if `textEditingController` is provided but `focusNode` isn't",
    (tester) async {
      expect(
        () => Boilerplate(
          child: MultiTriggerAutocomplete(
            autocompleteTriggers: const [],
            textEditingController: TextEditingController(),
          ),
        ),
        throwsAssertionError,
      );
    },
  );

  testWidgets(
    "should throw assertion if `focusNode` is provided but `textEditingController` isn't",
    (tester) async {
      expect(
        () => Boilerplate(
          child: MultiTriggerAutocomplete(
            autocompleteTriggers: const [],
            focusNode: FocusNode(),
          ),
        ),
        throwsAssertionError,
      );
    },
  );

  testWidgets(
    "should render fine if `initialValue` is defined without `textEditingController`",
    (tester) async {
      const multiTriggerAutocompleteKey = Key('multiTriggerAutocomplete');
      const multiTriggerAutocomplete = Boilerplate(
        child: MultiTriggerAutocomplete(
          key: multiTriggerAutocompleteKey,
          autocompleteTriggers: [],
          initialValue: TextEditingValue(text: 'initialValue'),
        ),
      );

      await tester.pumpWidget(multiTriggerAutocomplete);

      expect(find.byKey(multiTriggerAutocompleteKey), findsOneWidget);
    },
  );

  testWidgets(
    "should throw assertion if `initialValue` is defined along with `textEditingController`",
    (tester) async {
      expect(
        () => Boilerplate(
          child: MultiTriggerAutocomplete(
            autocompleteTriggers: const [],
            initialValue: const TextEditingValue(text: 'initialValue'),
            textEditingController: TextEditingController(),
            focusNode: FocusNode(),
          ),
        ),
        throwsAssertionError,
      );
    },
  );

  testWidgets(
    "should throw assertion if `initialValue` is defined along with `textEditingController` 2",
    (tester) async {
      expect(
        () => Boilerplate(
          child: MultiTriggerAutocomplete(
            autocompleteTriggers: const [],
            initialValue: const TextEditingValue(text: 'initialValue'),
            textEditingController: TextEditingController(),
            focusNode: FocusNode(),
          ),
        ),
        throwsAssertionError,
      );
    },
  );
}

class Boilerplate extends StatelessWidget {
  const Boilerplate({Key? key, this.child}) : super(key: key);

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }
}
