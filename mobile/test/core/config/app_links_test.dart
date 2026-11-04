import 'package:flutter_test/flutter_test.dart';
import 'package:readin/core/config/app_links.dart';

void main() {
  group('AppLinks.article (F24)', () {
    test('is the web address of the version being read', () {
      expect(AppLinks.article('rag-vs-fine-tuning', language: 'ar-EG'), 'https://readin.app/ar/a/rag-vs-fine-tuning');
      expect(AppLinks.article('rag-vs-fine-tuning', language: 'en'), 'https://readin.app/en/a/rag-vs-fine-tuning');
    });

    test('encodes the slug', () {
      expect(AppLinks.article('مقال جديد', language: 'ar-EG'),
          'https://readin.app/ar/a/%D9%85%D9%82%D8%A7%D9%84%20%D8%AC%D8%AF%D9%8A%D8%AF');
    });

    test('uses the default domain when WEB_ORIGIN is not set', () {
      expect(AppLinks.webOrigin, 'https://readin.app');
      expect(AppLinks.webHost, 'readin.app');
    });
  });

  group('AppLinks.originOf', () {
    test('keeps an https origin, without a trailing slash, lower case', () {
      expect(AppLinks.originOf('https://ReadIn.example/'), 'https://readin.example');
      expect(AppLinks.originOf(' https://readin.example '), 'https://readin.example');
      expect(AppLinks.originOf('https://readin.example:8443'), 'https://readin.example:8443');
    });

    test('refuses anything that is not an https origin', () {
      for (final value in [
        '',
        'readin.example',
        'http://readin.example',
        'https://readin.example/app',
        'https://readin.example?x=1',
        'https://readin.example#a',
        'https://user@readin.example',
        'readin://a/x',
      ]) {
        expect(AppLinks.originOf(value), isNull, reason: value);
      }
    });
  });
}
