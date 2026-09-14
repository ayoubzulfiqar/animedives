// Unit tests for the AnimeSiteConfig model.
import 'package:flutter_test/flutter_test.dart';
import 'package:animedives/models/site_config.dart';

void main() {
  group('AnimeSiteConfig', () {
    test('domainFromUrl extracts bare host', () {
      expect(AnimeSiteConfig.domainFromUrl('https://www.animeparadise.moe/'),
          'www.animeparadise.moe');
      expect(AnimeSiteConfig.domainFromUrl('https://anihq.cc/home/'), 'anihq.cc');
      expect(AnimeSiteConfig.domainFromUrl('not-a-url'), '');
      expect(AnimeSiteConfig.domainFromUrl(''), '');
    });

    test('injectedCss generates hide rules for each selector', () {
      const config = AnimeSiteConfig(
        name: 'Test',
        homepageUrl: 'https://test.com',
        domain: 'test.com',
        hideSelectors: ['header', '.popup', '#footer'],
      );
      expect(config.injectedCss, contains('header{display:none !important;}'));
      expect(config.injectedCss, contains('.popup{display:none !important;}'));
      expect(config.injectedCss, contains('#footer{display:none !important;}'));
    });

    test('injectedCss returns empty string for no selectors', () {
      const config = AnimeSiteConfig(
        name: 'Test',
        homepageUrl: 'https://test.com',
        domain: 'test.com',
      );
      expect(config.injectedCss, isEmpty);
    });

    test('injectedCssJs is safely escaped JSON', () {
      const config = AnimeSiteConfig(
        name: 'Test',
        homepageUrl: 'https://test.com',
        domain: 'test.com',
        hideSelectors: ['.card { color: red; }'],
      );
      // Should be valid JSON with escaped characters
      expect(config.injectedCssJs, isNotEmpty);
      expect(config.injectedCssJs, contains('"'));
    });

    test('toJson/fromJson round-trip preserves all fields', () {
      const config = AnimeSiteConfig(
        name: 'MySite',
        homepageUrl: 'https://mysite.to/anime',
        domain: 'mysite.to',
        logoUrl: 'https://mysite.to/img/logo.png',
        hideSelectors: ['header', '.ads'],
        safeCdnDomains: ['cdn.mysite.to', 'stream.mysite.to'],
      );
      final json = config.toJson();
      final restored = AnimeSiteConfig.fromJson(json);
      expect(restored.name, 'MySite');
      expect(restored.homepageUrl, 'https://mysite.to/anime');
      expect(restored.domain, 'mysite.to');
      expect(restored.logoUrl, 'https://mysite.to/img/logo.png');
      expect(restored.hideSelectors, ['header', '.ads']);
      expect(restored.safeCdnDomains, ['cdn.mysite.to', 'stream.mysite.to']);
    });

    test('toJsonString/fromJsonString round-trip', () {
      const config = AnimeSiteConfig(
        name: 'MySite',
        homepageUrl: 'https://mysite.to/anime',
        domain: 'mysite.to',
        hideSelectors: ['.popup'],
        safeCdnDomains: ['cdn.mysite.to'],
      );
      final json = config.toJsonString();
      final restored = AnimeSiteConfig.fromJsonString(json);
      expect(restored.name, 'MySite');
      expect(restored.hideSelectors, ['.popup']);
      expect(restored.safeCdnDomains, ['cdn.mysite.to']);
    });

    test('auto factory derives domain from homepageUrl', () {
      final config = AnimeSiteConfig.auto(
        name: 'AutoSite',
        homepageUrl: 'https://autosite.to/anime',
      );
      expect(config.domain, 'autosite.to');
      expect(config.logoUrl, '');
    });

    test('toJson/fromJson handles missing optional fields', () {
      final config = AnimeSiteConfig(
        name: 'Minimal',
        homepageUrl: 'https://minimal.to',
        domain: 'minimal.to',
      );
      final json = config.toJson();
      final restored = AnimeSiteConfig.fromJson(json);
      expect(restored.name, 'Minimal');
      expect(restored.logoUrl, '');
      expect(restored.hideSelectors, isEmpty);
      expect(restored.safeCdnDomains, isEmpty);
    });
  });

  group('global constants', () {
    test('globalHideSelectors is non-empty', () {
      expect(globalHideSelectors, isNotEmpty);
      expect(globalHideSelectors, contains('header'));
      expect(globalHideSelectors, contains('footer'));
    });

    test('globalSafeCdnDomains includes bot-protection hosts', () {
      expect(globalSafeCdnDomains, contains('cloudflare.com'));
      expect(globalSafeCdnDomains, contains('cloudflare.net'));
      expect(globalSafeCdnDomains, contains('turnstile.com'));
      expect(globalSafeCdnDomains, contains('recaptcha.net'));
      expect(globalSafeCdnDomains, contains('hcaptcha.com'));
    });

    test('globalSafeCdnDomains includes video CDNs', () {
      expect(globalSafeCdnDomains, contains('googlevideo.com'));
      expect(globalSafeCdnDomains, contains('cloudfront.net'));
      expect(globalSafeCdnDomains, contains('akamaihd.net'));
    });

    test('templateSites has 3 entries', () {
      expect(templateSites, hasLength(3));
    });
  });
}
