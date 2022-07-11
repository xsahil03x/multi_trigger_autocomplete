import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:multi_trigger_autocomplete/multi_trigger_autocomplete.dart';
import 'package:rate_limiter/rate_limiter.dart';

/// The type of the Autocomplete callback which returns the widget that
/// contains the input [TextField] or [TextFormField].
///
/// See also:
///
///   * [RawAutocomplete.fieldViewBuilder], which is of this type.
typedef MultiTriggerAutocompleteFieldViewBuilder = Widget Function(
  BuildContext context,
  TextEditingController textEditingController,
  FocusNode focusNode,
);

enum OptionsAlignment {
  /// The options are displayed below the field.
  ///
  /// This is the default.
  below,

  /// The options are displayed above the field.
  above;

  Anchor _toAnchor() {
    switch (this) {
      case OptionsAlignment.below:
        return const Aligned(
          follower: Alignment.topCenter,
          target: Alignment.bottomCenter,
        );
      case OptionsAlignment.above:
        return const Aligned(
          follower: Alignment.bottomCenter,
          target: Alignment.topCenter,
        );
    }
  }
}

/// A widget that provides a text field with autocomplete functionality.
class MultiTriggerAutocomplete extends StatefulWidget {
  /// Create an instance of StreamAutocomplete.
  ///
  /// [displayStringForOption], [optionsBuilder] and [optionsViewBuilder] must
  /// not be null.
  const MultiTriggerAutocomplete({
    super.key,
    required this.autocompleteTriggers,
    this.fieldViewBuilder = _defaultFieldViewBuilder,
    this.focusNode,
    this.textEditingController,
    this.initialValue,
    this.optionsAlignment = OptionsAlignment.below,
    this.debounceDuration = const Duration(milliseconds: 300),
  })  : assert((focusNode == null) == (textEditingController == null)),
        assert(
          !(textEditingController != null && initialValue != null),
          'textEditingController and initialValue cannot be simultaneously defined.',
        );

  /// The triggers that trigger autocomplete.
  final Iterable<AutocompleteTrigger> autocompleteTriggers;

  /// {@template flutter.widgets.RawAutocomplete.fieldViewBuilder}
  /// Builds the field whose input is used to get the options.
  ///
  /// Pass the provided [TextEditingController] to the field built here so that
  /// RawAutocomplete can listen for changes.
  /// {@endtemplate}
  final MultiTriggerAutocompleteFieldViewBuilder fieldViewBuilder;

  /// The [FocusNode] that is used for the text field.
  ///
  /// {@template flutter.widgets.RawAutocomplete.split}
  /// The main purpose of this parameter is to allow the use of a separate text
  /// field located in another part of the widget tree instead of the text
  /// field built by [fieldViewBuilder]. For example, it may be desirable to
  /// place the text field in the AppBar and the options below in the main body.
  ///
  /// When following this pattern, [fieldViewBuilder] can return
  /// `SizedBox.shrink()` so that nothing is drawn where the text field would
  /// normally be. A separate text field can be created elsewhere, and a
  /// FocusNode and TextEditingController can be passed both to that text field
  /// and to RawAutocomplete.
  ///
  /// {@tool dartpad}
  /// This examples shows how to create an autocomplete widget with the text
  /// field in the AppBar and the results in the main body of the app.
  ///
  /// ** See code in examples/api/lib/widgets/autocomplete/raw_autocomplete.focus_node.0.dart **
  /// {@end-tool}
  /// {@endtemplate}
  ///
  /// If this parameter is not null, then [textEditingController] must also be
  /// not null.
  final FocusNode? focusNode;

  /// The [TextEditingController] that is used for the text field.
  ///
  /// If this parameter is not null, then [focusNode] must also be not null.
  final TextEditingController? textEditingController;

  /// {@template flutter.widgets.RawAutocomplete.initialValue}
  /// The initial value to use for the text field.
  /// {@endtemplate}
  ///
  /// Setting the initial value does not notify [textEditingController]'s
  /// listeners, and thus will not cause the options UI to appear.
  ///
  /// This parameter is ignored if [textEditingController] is defined.
  final TextEditingValue? initialValue;

  /// The alignment of the options.
  ///
  /// The default value is [MultiTriggerAutocompleteAlignment.below].
  final OptionsAlignment optionsAlignment;

  /// The duration of the debounce period for the [TextEditingController].
  ///
  /// The default value is [300ms].
  final Duration debounceDuration;

  static Widget _defaultFieldViewBuilder(
    BuildContext context,
    TextEditingController textEditingController,
    FocusNode focusNode,
  ) {
    return _MultiTriggerAutocompleteField(
      focusNode: focusNode,
      textEditingController: textEditingController,
    );
  }

  @override
  _MultiTriggerAutocompleteState createState() =>
      _MultiTriggerAutocompleteState();
}

class _MultiTriggerAutocompleteState extends State<MultiTriggerAutocomplete> {
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;

  AutocompleteQuery? _currentQuery;
  AutocompleteTrigger? _currentTrigger;

  bool _hideOptions = false;

  // True if the state indicates that the options should be visible.
  bool get _shouldShowOptions {
    return !_hideOptions &&
        _focusNode.hasFocus &&
        _currentQuery != null &&
        _currentTrigger != null;
  }

  void _closeOptions() {
    final prev = _currentQuery;
    if (prev == null) return;

    _currentQuery = null;
    if (mounted) setState(() {});
  }

  void _showOptions(
    AutocompleteQuery query,
    AutocompleteTrigger trigger,
  ) {
    final prevQuery = _currentQuery;
    final prevTrigger = _currentTrigger;
    if (prevQuery == query && prevTrigger == trigger) return;

    _currentQuery = query;
    _currentTrigger = trigger;
    if (mounted) setState(() {});
  }

  // Checks if there is any invoked autocomplete trigger and returns the first
  // one along with the query that matches the current input.
  _AutocompleteInvokedTriggerWithQuery? _getInvokedTriggerWithQuery(
    TextEditingValue textEditingValue,
  ) {
    final autocompleteTriggers = widget.autocompleteTriggers.toSet();
    for (final trigger in autocompleteTriggers) {
      final query = trigger.invokingTrigger(textEditingValue);
      if (query != null) {
        return _AutocompleteInvokedTriggerWithQuery(trigger, query);
      }
    }
    return null;
  }

  // Called when _textEditingController changes.
  void _onChangedField() {
    debounce(
      () {
        final textEditingValue = _textEditingController.value;

        // If the text field is empty, then there is no need to do anything.
        if (textEditingValue.text.isEmpty) return _closeOptions();

        // If the text field is not empty, then we need to check if the
        // text field contains a trigger.
        final triggerWithQuery = _getInvokedTriggerWithQuery(textEditingValue);

        // If the text field does not contain a trigger, then there is no need
        // to do anything.
        if (triggerWithQuery == null) return _closeOptions();

        // If the text field contains a trigger, then we need to open the
        // portal.
        final trigger = triggerWithQuery.trigger;
        final query = triggerWithQuery.query;
        return _showOptions(query, trigger);
      },
      const Duration(milliseconds: 300),
    ).call();
  }

  // Called when the field's FocusNode changes.
  void _onChangedFocus() {
    // Options should no longer be hidden when the field is re-focused.
    _hideOptions = !_focusNode.hasFocus;
    if (mounted) setState(() {});
  }

  // Handle a potential change in textEditingController by properly disposing of
  // the old one and setting up the new one, if needed.
  void _updateTextEditingController(
      TextEditingController? old, TextEditingController? current) {
    if ((old == null && current == null) || old == current) {
      return;
    }
    if (old == null) {
      _textEditingController.removeListener(_onChangedField);
      _textEditingController.dispose();
      _textEditingController = current!;
    } else if (current == null) {
      _textEditingController.removeListener(_onChangedField);
      _textEditingController = TextEditingController();
    } else {
      _textEditingController.removeListener(_onChangedField);
      _textEditingController = current;
    }
    _textEditingController.addListener(_onChangedField);
  }

  // Handle a potential change in focusNode by properly disposing of the old one
  // and setting up the new one, if needed.
  void _updateFocusNode(FocusNode? old, FocusNode? current) {
    if ((old == null && current == null) || old == current) {
      return;
    }
    if (old == null) {
      _focusNode.removeListener(_onChangedFocus);
      _focusNode.dispose();
      _focusNode = current!;
    } else if (current == null) {
      _focusNode.removeListener(_onChangedFocus);
      _focusNode = FocusNode();
    } else {
      _focusNode.removeListener(_onChangedFocus);
      _focusNode = current;
    }
    _focusNode.addListener(_onChangedFocus);
  }

  @override
  void initState() {
    super.initState();
    _textEditingController = widget.textEditingController ??
        TextEditingController.fromValue(widget.initialValue);
    _textEditingController.addListener(_onChangedField);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onChangedFocus);
  }

  @override
  void didUpdateWidget(MultiTriggerAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTextEditingController(
      oldWidget.textEditingController,
      widget.textEditingController,
    );
    _updateFocusNode(oldWidget.focusNode, widget.focusNode);
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_onChangedField);
    if (widget.textEditingController == null) {
      _textEditingController.dispose();
    }
    _focusNode.removeListener(_onChangedFocus);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anchor = widget.optionsAlignment._toAnchor();
    final shouldShowOptions = _shouldShowOptions;
    final optionViewBuilder = shouldShowOptions
        ? _currentTrigger!.optionsViewBuilder(
            context,
            _currentQuery!,
            _textEditingController,
            _closeOptions,
          )
        : null;

    return PortalTarget(
      anchor: anchor,
      visible: shouldShowOptions,
      portalFollower: optionViewBuilder,
      child: widget.fieldViewBuilder(
        context,
        _textEditingController,
        _focusNode,
      ),
    );
  }
}

class _AutocompleteInvokedTriggerWithQuery {
  const _AutocompleteInvokedTriggerWithQuery(this.trigger, this.query);

  final AutocompleteTrigger trigger;
  final AutocompleteQuery query;
}

// The default Material-style Autocomplete text field.
class _MultiTriggerAutocompleteField extends StatelessWidget {
  const _MultiTriggerAutocompleteField({
    Key? key,
    required this.focusNode,
    required this.textEditingController,
  }) : super(key: key);

  final FocusNode focusNode;

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: textEditingController,
      focusNode: focusNode,
    );
  }
}
