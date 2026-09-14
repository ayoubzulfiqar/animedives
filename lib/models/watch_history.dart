import 'dart:convert';

/// A single watch-history entry for one anime the user was watching on a
/// provider.
///
/// Unlike a per-site record, each *anime* gets its own entry (keyed by
/// [id]), so watching episode 3 of "Naruto" and episode 7 of "One Piece" on
/// the same site both survive independently instead of overwriting each other.
///
/// [id] is a stable key derived from the site [domain] plus the anime's URL
/// slug, so re-visiting the same anime (even a different episode page) updates
/// the existing entry rather than creating a duplicate.
class WatchHistoryEntry {
  /// Stable unique key: "$domain::$slug". Used as the storage/dedup key.
  final String id;

  /// Site domain this entry belongs to (e.g. "anihq.cc").
  final String domain;

  /// Human-friendly provider name (e.g. "AniHQ") for grouping/display.
  final String providerName;

  /// Best-known title for this anime. Prefers the page's real document title
  /// (captured from the WebView); falls back to a humanized URL slug.
  final String title;

  /// The deepest URL the user reached for this anime (the episode/player page)
  /// so the WebView can be reopened straight there.
  final String url;

  /// Epoch milliseconds of the last update. Used for sorting (most recent
  /// first) and for showing a relative "last watched" label.
  final int lastWatchedAt;

  WatchHistoryEntry({
    required this.id,
    required this.domain,
    required this.providerName,
    required this.title,
    required this.url,
    required this.lastWatchedAt,
  });

  WatchHistoryEntry copyWith({
    String? id,
    String? domain,
    String? providerName,
    String? title,
    String? url,
    int? lastWatchedAt,
  }) => WatchHistoryEntry(
    id: id ?? this.id,
    domain: domain ?? this.domain,
    providerName: providerName ?? this.providerName,
    title: title ?? this.title,
    url: url ?? this.url,
    lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'domain': domain,
        'providerName': providerName,
        'title': title,
        'url': url,
        'lastWatchedAt': lastWatchedAt,
      };

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      WatchHistoryEntry(
        id: json['id'] as String,
        domain: json['domain'] as String,
        providerName: json['providerName'] as String,
        title: json['title'] as String,
        url: json['url'] as String,
        lastWatchedAt: json['lastWatchedAt'] as int,
      );

  /// Convenience accessor that returns a JSON string (used by
  /// [SharedPreferences.setStringList]).
  String toJsonString() => jsonEncode(toJson());

  factory WatchHistoryEntry.fromJsonString(String raw) =>
      WatchHistoryEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Builds the stable history [id] for an anime page.
///
/// The id is "$domain::$slug" where [slug] is the most "anime-like" path
/// segment of [url] (the segment with the most alphabetic characters that is
/// not a generic navigation keyword or an episode/chapter marker). Grouping by
/// this means different episodes of the same anime collapse into one updatable
/// entry, while different animes stay separate. Falls back to 'home' when the
/// URL has no usable segments.
String animeHistoryId(String domain, String url) {
  final uri = Uri.tryParse(url);
  final host = (uri?.host.isNotEmpty == true ? uri!.host : domain)
      .toLowerCase()
      .replaceFirst(RegExp(r'^www\.'), '');

  final segments = (uri?.pathSegments ?? const <String>[])
      .where((s) => s.isNotEmpty)
      .toList();

  String slug;
  if (segments.isEmpty) {
    slug = 'home';
  } else {
    // Strip trailing episode/chapter markers from each segment so
    // "one-piece-ep-5" becomes "one-piece" and "episode-3" becomes "" (then
    // filtered out as empty).
    final episodeStrip =
        RegExp(r'[-_]?(?:ep|episode|ch|chapter)[-_]?\d+$', caseSensitive: false);
    final cleaned = <String>[];
    for (final s in segments) {
      final stripped = s.replaceAll(episodeStrip, '').trim();
      if (stripped.isNotEmpty) cleaned.add(stripped);
    }

    // Exclude generic navigation segments and pure episode/chapter markers
    // so the anime title wins.
    const generic = {
      'home', 'homepage', 'index', 'watch', 'anime', 'tv', 'movies',
      'series', 'browse', 'latest', 'popular', 'trending',
      'discover', 'search',
    };
    final candidates = cleaned.where((s) {
      final lower = s.toLowerCase();
      if (generic.contains(lower)) return false;
      // Skip standalone episode/chapter markers left after stripping.
      if (RegExp(r'^(ep|episode|ch|chapter)$', caseSensitive: false).hasMatch(lower)) return false;
      return true;
    }).toList();

    if (candidates.isEmpty) {
      // Nothing left after filtering — fall back to the most alphabetic segment.
      cleaned.sort((a, b) => _letterCount(b).compareTo(_letterCount(a)));
      slug = cleaned.isNotEmpty ? cleaned.first : 'home';
    } else {
      candidates.sort((a, b) => _letterCount(b).compareTo(_letterCount(a)));
      slug = candidates.first;
    }
  }
  return '$host::$slug';
}

int _letterCount(String s) =>
    s.runes.where((r) => (r >= 65 && r <= 90) || (r >= 97 && r <= 122)).length;

/// Turns a URL slug into a readable title, e.g. "one-piece" -> "One Piece".
String humanizeSlug(String slug) {
  final cleaned = slug
      .replaceAll(RegExp(r'\.html?$'), '')
      .replaceAll(RegExp(r'[-_]episode.*$', caseSensitive: false), '')
      .replaceAll(RegExp(r'[-_ ]+ep\d+.*$', caseSensitive: false), '')
      .replaceAll(RegExp(r'[-_]+'), ' ')
      .trim();
  if (cleaned.isEmpty) return slug;
  return cleaned
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
