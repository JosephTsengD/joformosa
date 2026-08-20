// @spec T-075/Scenario-PkceChallenge
// @spec T-075/Scenario-StateVerification
// @spec T-075/Scenario-CallbackErrors
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joformosa/features/auth/data/line_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  LineAuthService build({int seed = 42}) => LineAuthService(
        channelId: '2000000000',
        redirectUri: 'https://josephtsengd.github.io/joformosa/auth/line',
        prefs: prefs,
        random: Random(seed),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  group('PkceChallenge', () {
    test('challenge 是 base64url(sha256(verifier)) 且無 padding', () {
      const verifier = 'test-verifier-1234567890';
      final challenge = LineAuthService.challengeFor(verifier);

      final expected = base64Url
          .encode(sha256.convert(utf8.encode(verifier)).bytes)
          .replaceAll('=', '');

      expect(challenge, expected);
      // RFC 7636 明確要求無 padding。留著 = 會被回 invalid_grant，
      // 而錯誤訊息完全不會提到 padding。
      expect(challenge.contains('='), isFalse);
    });

    test('challenge 不等於 verifier（不是純文字 PKCE）', () {
      const verifier = 'plain-text-should-not-pass-through';
      expect(LineAuthService.challengeFor(verifier), isNot(verifier));
    });

    test('相同 verifier 產生相同 challenge，不同則不同', () {
      expect(LineAuthService.challengeFor('a'), LineAuthService.challengeFor('a'));
      expect(
        LineAuthService.challengeFor('a'),
        isNot(LineAuthService.challengeFor('b')),
      );
    });

    test('授權網址帶上 S256 而非 plain', () async {
      final req = await build().start();
      final uri = Uri.parse(req.authorizeUrl);

      expect(uri.queryParameters['code_challenge_method'], 'S256');
      expect(
        uri.queryParameters['code_challenge'],
        LineAuthService.challengeFor(req.codeVerifier),
      );
    });
  });

  group('授權網址', () {
    test('只要 openid profile，不要 email（email 需要事前送審）', () async {
      final req = await build().start();
      final scope = Uri.parse(req.authorizeUrl).queryParameters['scope'];

      expect(scope, 'openid profile');
      expect(scope, isNot(contains('email')));
    });

    test('redirect_uri 原樣帶入，不做任何調整', () async {
      final req = await build().start();
      expect(
        Uri.parse(req.authorizeUrl).queryParameters['redirect_uri'],
        'https://josephtsengd.github.io/joformosa/auth/line',
      );
    });

    test('每次都產生不同的 state 與 nonce', () async {
      final a = await build(seed: 1).start();
      final b = await build(seed: 2).start();

      expect(a.state, isNot(b.state));
      expect(a.nonce, isNot(b.nonce));
      expect(a.codeVerifier, isNot(b.codeVerifier));
    });

    test('verifier 長度符合 RFC 7636（43–128）', () async {
      final req = await build().start();
      expect(req.codeVerifier.length, inInclusiveRange(43, 128));
    });
  });

  group('StateVerification', () {
    test('state 相符時回傳 code 與 verifier', () async {
      final service = build();
      final req = await service.start();

      final result = await service.complete(
        Uri.parse('https://x/auth/line?code=abc123&state=${req.state}'),
      );

      expect(result, isA<LineCallbackOk>());
      final ok = result as LineCallbackOk;
      expect(ok.code, 'abc123');
      expect(ok.codeVerifier, req.codeVerifier);
      expect(ok.nonce, req.nonce);
    });

    test('state 不符時拒絕——這是 CSRF 的唯一防線', () async {
      final service = build();
      await service.start();

      final result = await service.complete(
        Uri.parse('https://x/auth/line?code=attacker-code&state=wrong'),
      );

      expect(result, isA<LineCallbackError>());
      expect(
        (result as LineCallbackError).reason,
        LineCallbackFailure.stateMismatch,
      );
    });

    test('state 不符時清除待處理狀態，攻擊者無法重試', () async {
      final service = build();
      await service.start();
      await service.complete(Uri.parse('https://x/auth/line?code=c&state=bad'));

      expect(service.hasPendingRequest, isFalse);
    });

    test('用過一次之後不能重放', () async {
      final service = build();
      final req = await service.start();
      final uri = Uri.parse('https://x/auth/line?code=abc&state=${req.state}');

      expect(await service.complete(uri), isA<LineCallbackOk>());
      // 第二次應該失敗：待處理狀態已被消耗
      expect(await service.complete(uri), isA<LineCallbackError>());
    });
  });

  group('CallbackErrors', () {
    test('沒有待處理流程時拒絕（直接貼網址或被注入）', () async {
      final result = await build().complete(
        Uri.parse('https://x/auth/line?code=injected&state=whatever'),
      );

      expect(
        (result as LineCallbackError).reason,
        LineCallbackFailure.noPendingRequest,
      );
    });

    test('使用者按取消時可與其他錯誤區分', () async {
      final service = build();
      final req = await service.start();

      final result = await service.complete(
        Uri.parse('https://x/auth/line?error=access_denied&state=${req.state}'),
      );

      // 使用者取消不該顯示錯誤紅字，那是他自己的選擇
      expect(
        (result as LineCallbackError).reason,
        LineCallbackFailure.userCancelled,
      );
    });

    test('LINE 端錯誤與使用者取消分開處理', () async {
      final service = build();
      final req = await service.start();

      final result = await service.complete(
        Uri.parse('https://x/auth/line?error=server_error&state=${req.state}'),
      );

      expect(
        (result as LineCallbackError).reason,
        LineCallbackFailure.providerError,
      );
    });

    test('缺少 code 時拒絕', () async {
      final service = build();
      final req = await service.start();

      final result =
          await service.complete(Uri.parse('https://x/auth/line?state=${req.state}'));

      expect(
        (result as LineCallbackError).reason,
        LineCallbackFailure.missingCode,
      );
    });
  });
}
