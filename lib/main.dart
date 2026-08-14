import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'app/app.dart';
import 'app/providers.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // 設定齊全才連後端。缺設定時整個 App 走本地合成資料，
  // 這讓 `flutter run` 在零設定的情況下仍然可用。
  if (AppConfig.hasSupabase) {
    try {
      await sb.Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // 不是 anonKey：那個參數已被標記淘汰。
        // 新的 publishable key 也接受舊的 anon key 值，所以兩者都能傳。
        publishableKey: AppConfig.supabaseKey,
        authOptions: const sb.FlutterAuthClientOptions(
          authFlowType: sb.AuthFlowType.pkce,
        ),
      );
      // 匿名登入讓使用者不必註冊就能收藏、送出社團。
      // RLS 的 auth.uid() 對匿名使用者一樣有效，授權不受影響。
      if (sb.Supabase.instance.client.auth.currentUser == null) {
        await sb.Supabase.instance.client.auth.signInAnonymously();
      }
    } on Object catch (_) {
      // 初始化失敗不可以讓 App 開不起來。
      // ResilientCrewRepository 會在讀取時降級到本地資料。
    }
  }

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const JoinCrewApp(),
    ),
  );
}
