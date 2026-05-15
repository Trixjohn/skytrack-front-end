import 'dart:async';
import 'package:flutter/material.dart';
import 'app_theme.dart';

// Fallback popular cities shown before any query
const _popularCities = [
  // --- Original List ---
  'Manila', 'Cebu City', 'Davao', 'Quezon City', 'Makati', 
  'Iloilo', 'Bacolod', 'Cagayan de Oro', 'Zamboanga', 'Baguio',
  'Tokyo', 'Singapore', 'Bangkok', 'London', 'New York', 
  'Sydney', 'Dubai', 'Paris', 'Jakarta', 'Seoul',

  // --- Added Philippine Majority Hubs ---
  // High-Population Metro Manila Cities
  'Caloocan', 'Taguig', 'Pasig', 'Parañaque', 'Valenzuela', 
  'Las Piñas', 'Muntinlupa', 'Marikina', 'Pasay', 'Mandaluyong',

  // Major Provincial & Regional Hubs
  'Antipolo', 'Dasmariñas', 'Bacoor', 'San Jose del Monte', 
  'General Santos', 'Lapu-Lapu City', 'Calamba', 'Imus', 
  'Angeles City', 'Batangas City', 'Tarlac City', 'Butuan', 
  'Biñan', 'Santa Rosa', 'Lucena', 'Puerto Princesa'
];


class CitySearchBar extends StatefulWidget {
  final void Function(String city) onSearch;
  final void Function() onSave;
  final bool loading;

  const CitySearchBar({
    super.key,
    required this.onSearch,
    required this.onSave,
    this.loading = false,
  });

  @override
  State<CitySearchBar> createState() => _CitySearchBarState();
}

class _CitySearchBarState extends State<CitySearchBar> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<String> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_focusNode.hasFocus) _hideDropdown();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  // ── Suggestion fetch ────────────────────────────────────────────────────────

  Future<List<String>> _fetchSuggestions(String query) async {
    // Local filter only — backend has no /cities/search endpoint
    final q = query.toLowerCase();
    return _popularCities
        .where((c) => c.toLowerCase().contains(q))
        .take(8)
        .toList();
  }


  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.isEmpty) {
      _hideDropdown();
      return;
    }
    
    // Show local results instantly for better UX
    final queryLower = value.toLowerCase();
    final localResults = _popularCities
        .where((c) => c.toLowerCase().contains(queryLower))
        .take(6)
        .toList();
    if (localResults.isNotEmpty) {
      _suggestions = localResults;
      _showSuggestions();
    } else {
      _hideDropdown();
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await _fetchSuggestions(value);
      if (!mounted) return;
      if (results.isNotEmpty) {
        _suggestions = results;
        _showSuggestions();
      } else if (localResults.isEmpty) {
        _hideDropdown();
      }
    });
  }

  // ── Overlay management ──────────────────────────────────────────────────────

  void _showSuggestions() {
    if (_overlayEntry == null) {
      _overlayEntry = _buildOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlay() => OverlayEntry(
        builder: (ctx) => CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 72, // account for save btn padding
                child: _SuggestionsDropdown(
                  suggestions: _suggestions,
                  query: _ctrl.text,
                  onSelect: (city) {
                    _ctrl.text = city;
                    _hideDropdown();
                    _focusNode.unfocus();
                    widget.onSearch(city);
                  },
                ),
              ),
            ),
          ),
        ),
      );

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(
          child: CompositedTransformTarget(
            link: _layerLink,
            child: TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              onChanged: _onChanged,
              onSubmitted: (v) {
                _hideDropdown();
                widget.onSearch(v);
              },
              style: TextStyle(color: c.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle:
                    TextStyle(color: c.textTertiary, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: c.textTertiary, size: 20),
                suffixIcon: widget.loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : _ctrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: c.textTertiary, size: 18),
                            onPressed: () {
                              _ctrl.clear();
                              _hideDropdown();
                            },
                          )
                        : IconButton(
                            icon: Icon(Icons.arrow_forward_rounded,
                                color: c.blue),
                            onPressed: () {
                              _hideDropdown();
                              widget.onSearch(_ctrl.text);
                            },
                          ),
                filled: true,
                fillColor: c.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide:
                      BorderSide(color: c.border, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide:
                      BorderSide(color: c.border, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: c.blue, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.onSave,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Icon(Icons.bookmark_add_outlined,
                color: c.blue, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ── Dropdown widget ─────────────────────────────────────────────────────────

class _SuggestionsDropdown extends StatelessWidget {
  final List<String> suggestions;
  final String query;
  final void Function(String) onSelect;

  const _SuggestionsDropdown({
    required this.suggestions,
    required this.query,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: c.border),
          itemBuilder: (_, i) {
            final city = suggestions[i];
            return _SuggestionTile(
                city: city, query: query, onTap: () => onSelect(city));
          },
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String city;
  final String query;
  final VoidCallback onTap;

  const _SuggestionTile(
      {required this.city, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.ac;
    // Bold-highlight the matching part
    final lowerCity = city.toLowerCase();
    final lowerQ = query.toLowerCase();
    final matchIdx = lowerCity.indexOf(lowerQ);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.blueLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_city_outlined,
                color: c.blue, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: matchIdx >= 0
                ? RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 14, color: c.textPrimary),
                      children: [
                        TextSpan(text: city.substring(0, matchIdx)),
                        TextSpan(
                          text: city.substring(
                              matchIdx, matchIdx + query.length),
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: c.blue),
                        ),
                        TextSpan(
                            text: city.substring(matchIdx + query.length)),
                      ],
                    ),
                  )
                : Text(city,
                    style: TextStyle(
                        fontSize: 14, color: c.textPrimary)),
          ),
          Icon(Icons.north_west_rounded,
              size: 14, color: c.textTertiary),
        ]),
      ),
    );
  }
}
