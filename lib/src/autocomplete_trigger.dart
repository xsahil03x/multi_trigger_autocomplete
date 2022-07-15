import 'package:flutter/material.dart';
import 'package:multi_trigger_autocomplete/src/autocomplete_query.dart';

/// The type of the [AutocompleteTrigger] callback which returns a [Widget] that
/// displays the specified [options].
typedef AutocompleteTriggerOptionsViewBuilder = Widget Function(
  BuildContext context,
  AutocompleteQuery autocompleteQuery,
  TextEditingController textEditingController,
);

class AutocompleteTrigger {
  /// Creates a [AutocompleteTrigger] which can be used to trigger
  /// autocomplete suggestions.
  const AutocompleteTrigger({
    required this.trigger,
    required this.optionsViewBuilder,
    this.triggerOnlyAtStart = false,
    this.minimumRequiredCharacters = 0,
  });

  /// The trigger character.
  ///
  /// eg. '@', '#', ':'
  final String trigger;

  /// Whether the [trigger] should only be recognised at the start of the input.
  final bool triggerOnlyAtStart;

  /// The minimum required characters for the [trigger] to start recognising
  /// a autocomplete options.
  final int minimumRequiredCharacters;

  /// Builds the selectable options widgets from a list of options objects.
  ///
  /// The options are displayed floating below the field using a
  /// [CompositedTransformFollower] inside of an [Overlay], not at the same
  /// place in the widget tree as [RawAutocomplete].
  ///
  /// In order to track which item is highlighted by keyboard navigation, the
  /// resulting options will be wrapped in an inherited
  /// [AutocompleteHighlightedOption] widget.
  /// Inside this callback, the index of the highlighted option can be obtained
  /// from [AutocompleteHighlightedOption.of] to display the highlighted option
  /// with a visual highlight to indicate it will be the option selected from
  /// the keyboard.
  final AutocompleteTriggerOptionsViewBuilder optionsViewBuilder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutocompleteTrigger &&
          runtimeType == other.runtimeType &&
          trigger == other.trigger &&
          triggerOnlyAtStart == other.triggerOnlyAtStart &&
          minimumRequiredCharacters == other.minimumRequiredCharacters;

  @override
  int get hashCode =>
      trigger.hashCode ^
      triggerOnlyAtStart.hashCode ^
      minimumRequiredCharacters.hashCode;

  /// Checks if the user is invoking the recognising [trigger] and returns
  /// the autocomplete query if so.
  AutocompleteQuery? invokingTrigger(TextEditingValue textEditingValue) {
    final text = textEditingValue.text;
    final cursorPosition = textEditingValue.selection.baseOffset;

    // Find the first [trigger] location before the input cursor.
    final firstTriggerIndexBeforeCursor =
        text.substring(0, cursorPosition).lastIndexOf(trigger);

    // If the [trigger] is not found before the cursor, then it's not a trigger.
    if (firstTriggerIndexBeforeCursor == -1) return null;

    // If the [trigger] is found before the cursor, but the [trigger] is only
    // recognised at the start of the input, then it's not a trigger.
    if (triggerOnlyAtStart && firstTriggerIndexBeforeCursor != 0) {
      return null;
    }

    // Only show typing suggestions after a space, or at the start of the input
    // valid examples: "@user", "Hello @user"
    // invalid examples: "Hello@user"
    final textBeforeTrigger = text.substring(0, firstTriggerIndexBeforeCursor);
    if (textBeforeTrigger.isNotEmpty && !textBeforeTrigger.endsWith(' ')) {
      return null;
    }

    // The suggestion range. Protect against invalid ranges.
    final suggestionStart = firstTriggerIndexBeforeCursor + trigger.length;
    final suggestionEnd = cursorPosition;
    if (suggestionStart > suggestionEnd) return null;

    // Fetch the suggestion text. The suggestions can't have spaces.
    // valid example: "@luke_skywa..."
    // invalid example: "@luke skywa..."
    final suggestionText = text.substring(suggestionStart, suggestionEnd);
    if (suggestionText.contains(' ')) return null;

    // A minimum number of characters can be provided to only show
    // suggestions after the customer has input enough characters.
    if (suggestionText.length < minimumRequiredCharacters) return null;

    return AutocompleteQuery(
      query: suggestionText,
      selection: TextSelection(
        baseOffset: suggestionStart,
        extentOffset: suggestionEnd,
      ),
    );
  }
}
