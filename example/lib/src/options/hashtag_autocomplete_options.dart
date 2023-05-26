import 'package:example/src/data.dart';
import 'package:flutter/material.dart';

import 'package:example/src/models.dart';

class HashtagAutocompleteOptions extends StatefulWidget {
  const HashtagAutocompleteOptions({
    Key? key,
    required this.query,
    required this.onHashtagTap,
  }) : super(key: key);

  final String query;
  final ValueSetter<Hashtag> onHashtagTap;

  @override
  State<HashtagAutocompleteOptions> createState() =>
      _HashtagAutocompleteOptionsState();
}

class _HashtagAutocompleteOptionsState
    extends State<HashtagAutocompleteOptions> {
  bool _isLoading = false;
  Iterable<Hashtag> _items = List.empty();

  @override
  void initState() {
    super.initState();

    _search();
  }

  @override
  void didUpdateWidget(HashtagAutocompleteOptions oldWidget) {
    super.didUpdateWidget(oldWidget);

    _search();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    _items = kHashtags.where((it) {
      final normalizedOption = it.name.toLowerCase();
      final normalizedQuery = widget.query.toLowerCase();
      return normalizedOption.contains(normalizedQuery);
    });

    _isLoading = false;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color(0xFFE9EAF4),
            child: ListTile(
              dense: true,
              horizontalTitleGap: 0,
              title: Text("Hashtags matching '${widget.query}'"),
            ),
          ),
          const Divider(height: 0),
          LimitedBox(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
            child: (_isLoading) ? _buildLoader() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final hashtag = _items.elementAt(i);
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF7F7F8),
            backgroundImage: NetworkImage(
              hashtag.image,
              scale: 0.5,
            ),
          ),
          title: Text('#${hashtag.name}'),
          subtitle: Text(
            hashtag.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => widget.onHashtagTap(hashtag),
        );
      },
    );
  }
}
