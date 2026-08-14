// LINE Login v2.1 → Supabase session 交換。
//
// 為什麼一定要有這個 Edge Function？
// ─────────────────────────────────────────────────────────
// LINE 的 token endpoint 需要 channel_secret。任何放進 App bundle 的密鑰
// 都能被反編譯取出（Android 用 apktool、iOS 用 strings 就夠了），
// 所以 secret 必須待在伺服器端。App 只負責開瀏覽器拿 code。
//
// 部署：supabase functions deploy line-auth --no-verify-jwt
// 密鑰：supabase secrets set LINE_CHANNEL_ID=... LINE_CHANNEL_SECRET=...

import { createClient } from 'jsr:@supabase/supabase-js@2';

const LINE_CHANNEL_ID = Deno.env.get('LINE_CHANNEL_ID')!;
const LINE_CHANNEL_SECRET = Deno.env.get('LINE_CHANNEL_SECRET')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

interface Body {
  code: string;
  codeVerifier: string;
  redirectUri: string;
  nonce: string;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  try {
    const { code, codeVerifier, redirectUri, nonce }: Body = await req.json();

    // ① code → token（PKCE：帶 code_verifier）
    const tokenRes = await fetch('https://api.line.me/oauth2/v2.1/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: redirectUri,
        client_id: LINE_CHANNEL_ID,
        client_secret: LINE_CHANNEL_SECRET,
        code_verifier: codeVerifier,
      }),
    });
    if (!tokenRes.ok) {
      return json({ error: 'line_token_exchange_failed' }, 401);
    }
    const token = await tokenRes.json();

    // ② 驗證 id_token。**一定要用 LINE 的 verify endpoint 或自行驗簽**，
    //    不可直接 base64 decode 就信任——那等於沒有驗證。
    const verifyRes = await fetch('https://api.line.me/oauth2/v2.1/verify', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        id_token: token.id_token,
        client_id: LINE_CHANNEL_ID,
        nonce, // ③ 比對 nonce，防重放攻擊
      }),
    });
    if (!verifyRes.ok) {
      return json({ error: 'line_id_token_invalid' }, 401);
    }
    const profile = await verifyRes.json(); // { sub, name, picture, ... }

    // ④ 以 service role 建立或取得 Supabase 使用者
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE);
    const lineUserId = profile.sub as string;
    // LINE 不一定提供 email，所以用穩定的合成 email 當帳號鍵
    const email = `line_${lineUserId}@line.joincrew.local`;

    const { data: created, error: createErr } = await admin.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: {
        provider: 'line',
        line_user_id: lineUserId,
        display_name: profile.name,
        avatar_url: profile.picture,
      },
    });

    let userId = created?.user?.id;
    if (createErr) {
      // 已存在 → 查出既有使用者（帳號升級路徑）
      const { data: list } = await admin.auth.admin.listUsers();
      userId = list.users.find((u) => u.email === email)?.id;
      if (!userId) return json({ error: 'user_lookup_failed' }, 500);
    }

    // ⑤ 簽發 Supabase session（magic link 的 token 可直接換 session）
    const { data: link, error: linkErr } = await admin.auth.admin.generateLink({
      type: 'magiclink',
      email,
    });
    if (linkErr) return json({ error: 'session_issue_failed' }, 500);

    return json({
      userId,
      email,
      displayName: profile.name,
      avatarUrl: profile.picture,
      // App 端用 verifyOtp({ type: 'magiclink', token_hash }) 換 session
      tokenHash: link.properties?.hashed_token,
    });
  } catch (_e) {
    // 不回傳內部錯誤細節給客戶端（避免資訊洩漏）
    return json({ error: 'internal' }, 500);
  }
});

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
