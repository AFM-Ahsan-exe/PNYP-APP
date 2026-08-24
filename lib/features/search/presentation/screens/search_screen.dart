import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search events, news, opportunities...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _query = '';
                            _results = [];
                            _error = null;
                          });
                        },
                      )
                    : null,
                filled: true,
              ),
              onChanged: (value) {
                setState(() => _query = value);
                if (value.isNotEmpty) {
                  _performSearch(value);
                } else {
                  setState(() {
                    _results = [];
                    _error = null;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Search for events, news, and opportunities', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Could not load search results',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _performSearch(_query),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No results found', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) => _SearchResultTile(result: _results[index]),
    );
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });

    try {
      final results = <Map<String, dynamic>>[];
      final searchLower = query.toLowerCase();

      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .limit(10)
          .get();
      for (final doc in eventsSnapshot.docs) {
        final data = doc.data();
        if (data['title']?.toString().toLowerCase().contains(searchLower) ?? false) {
          results.add({'id': doc.id, ...data, 'type': 'event'});
        }
      }

      final newsSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .limit(10)
          .get();
      for (final doc in newsSnapshot.docs) {
        final data = doc.data();
        if (data['title']?.toString().toLowerCase().contains(searchLower) ?? false) {
          results.add({'id': doc.id, ...data, 'type': 'news'});
        }
      }

      final opportunitiesSnapshot = await FirebaseFirestore.instance
          .collection('opportunities')
          .limit(10)
          .get();
      for (final doc in opportunitiesSnapshot.docs) {
        final data = doc.data();
        if (data['title']?.toString().toLowerCase().contains(searchLower) ?? false) {
          results.add({'id': doc.id, ...data, 'type': 'opportunity'});
        }
      }

      setState(() {
        _isLoading = false;
        _results = results;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }
}

class _SearchResultTile extends StatelessWidget {
  final Map<String, dynamic> result;

  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final title = result['title'] as String? ?? 'Untitled';
    final type = result['type'] as String? ?? 'unknown';
    final icon = _getIconForType(type);
    final color = _getColorForType(type);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(type.toUpperCase()),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'event':
        return Icons.event_rounded;
      case 'news':
        return Icons.article_rounded;
      case 'opportunity':
        return Icons.work_outline_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'event':
        return const Color(0xFF1565C0);
      case 'news':
        return const Color(0xFF2E7D32);
      case 'opportunity':
        return const Color(0xFF1A3A5C);
      default:
        return Colors.grey;
    }
  }
}
