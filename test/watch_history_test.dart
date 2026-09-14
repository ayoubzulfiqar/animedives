// Unit tests for the watch-history model: ID generation, slug humanization,
// and JSON round-trip serialization.
import 'package:flutter_test/flutter_test.dart';
import 'package:animedives/models/watch_history.dart';

void main() {
  group('animeHistoryId', () {
    test('extracts the anime slug from a nested episode URL', () {
      final id = animeHistoryId('anihq.cc', 'https://anihq.cc/anime/naruto/episode-3');
      expect(id, 'anihq.cc::naruto');
    });

    test('strips compound episode suffixes from slug', () {
      final id = animeHistoryId('animex.one', 'https://animex.one/anime/one-piece-ep-5');
      expect(id, 'animex.one::one-piece');
    });

    test('strips episode markers from last segment', () {
      final id = animeHistoryId('animepahe.pw', 'https://animepahe.pw/naruto-episode-2');
      expect(id, 'animepahe.pw::naruto');
    });

    test('returns generic slug for bare homepage', () {
      final id = animeHistoryId('anime.nexus', 'https://anime.nexus/');
      expect(id, 'anime.nexus::home');
    });

    test('returns generic slug for /home path', () {
      final id = animeHistoryId('reanime.to', 'https://reanime.to/home');
      expect(id, 'reanime.to::home');
    });

    test('normalizes www prefix and case in domain', () {
      final id = animeHistoryId('animeya.cc', 'https://WWW.Animeya.cc/watch/seirei/123');
      expect(id, 'animeya.cc::seirei');
    });

    test('falls back to domain for non-URL input', () {
      // "not-a-url" has no host, so the domain parameter is used as fallback.
      final id = animeHistoryId('example.com', 'not-a-url');
      expect(id, 'example.com::not-a-url');
    });

    test('falls back to home for empty path segments', () {
      final id = animeHistoryId('example.com', 'https://example.com');
      expect(id, 'example.com::home');
    });
  });

  group('humanizeSlug', () {
    test('capitalizes hyphenated words', () {
      expect(humanizeSlug('one-piece'), 'One Piece');
    });

    test('removes .html suffix', () {
      expect(humanizeSlug('one-piece.html'), 'One Piece');
    });

    test('removes episode suffixes', () {
      expect(humanizeSlug('one-piece-episode-5'), 'One Piece');
      expect(humanizeSlug('naruto-ep10'), 'Naruto');
    });

    test('returns empty string for empty input', () {
      expect(humanizeSlug(''), '');
    });

    test('handles underscore separators', () {
      expect(humanizeSlug('my_hero_academia'), 'My Hero Academia');
    });
  });

  group('WatchHistoryEntry', () {
    test('toJson/fromJson round-trip preserves data', () {
      final entry = WatchHistoryEntry(
        id: 'anihq.cc::naruto',
        domain: 'anihq.cc',
        providerName: 'AniHQ',
        title: 'Naruto',
        url: 'https://anihq.cc/anime/naruto/episode-3',
        lastWatchedAt: 1700000000000,
      );
      final json = entry.toJson();
      final restored = WatchHistoryEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.domain, entry.domain);
      expect(restored.providerName, entry.providerName);
      expect(restored.title, entry.title);
      expect(restored.url, entry.url);
      expect(restored.lastWatchedAt, entry.lastWatchedAt);
    });

    test('copyWith updates only provided fields', () {
      final entry = WatchHistoryEntry(
        id: 'id',
        domain: 'domain',
        providerName: 'provider',
        title: 'title',
        url: 'url',
        lastWatchedAt: 100,
      );
      final copy = entry.copyWith(title: 'new-title');
      expect(copy.title, 'new-title');
      expect(copy.id, 'id');
      expect(copy.url, 'url');
    });

    test('toJsonString/fromJsonString round-trip', () {
      final entry = WatchHistoryEntry(
        id: 'id',
        domain: 'domain',
        providerName: 'provider',
        title: 'title',
        url: 'url',
        lastWatchedAt: 100,
      );
      final json = entry.toJsonString();
      final restored = WatchHistoryEntry.fromJsonString(json);
      expect(restored, isNotNull);
      expect(restored.id, entry.id);
    });
  });
}