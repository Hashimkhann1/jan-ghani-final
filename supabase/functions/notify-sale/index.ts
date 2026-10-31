// Customer ki nayi sale par PWA push notification bhejta hai.
// Trigger: public.fn_notify_customer_sale (2026_10_31_customer_push_notifications.sql)
//
// Deploy (trigger ke paas user JWT nahi hota, secret header se verify hota hai):
//   supabase functions deploy notify-sale --no-verify-jwt
// Secrets:
//   supabase secrets set VAPID_PUBLIC_KEY=... VAPID_PRIVATE_KEY=... \
//     VAPID_SUBJECT=mailto:you@example.com WEBHOOK_SECRET=<push_config wala secret>
//   (SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY Supabase khud deta hai)
//
// VAPID keys:  npx web-push generate-vapid-keys

import webpush from 'npm:web-push@3.6.7';
import { createClient } from 'npm:@supabase/supabase-js@2';

webpush.setVapidDetails(
  Deno.env.get('VAPID_SUBJECT') ?? 'mailto:admin@example.com',
  Deno.env.get('VAPID_PUBLIC_KEY')!,
  Deno.env.get('VAPID_PRIVATE_KEY')!,
);

const sb = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const rs = (n: unknown) => `Rs ${Math.round(Number(n) || 0).toLocaleString('en-US')}`;

Deno.serve(async (req) => {
  if (req.headers.get('x-webhook-secret') !== Deno.env.get('WEBHOOK_SECRET')) {
    return new Response('unauthorized', { status: 401 });
  }

  const inv = await req.json();
  if (!inv?.customer_id) return new Response('no customer', { status: 200 });

  const { data: users } = await sb
    .from('users')
    .select('id')
    .eq('role', 'customer')
    .eq('customer_token', String(inv.customer_id));
  const ids = (users ?? []).map((u: { id: string }) => u.id);
  if (ids.length === 0) return new Response('no account', { status: 200 });

  const { data: subs } = await sb
    .from('customer_push_subscriptions')
    .select('id, endpoint, p256dh, auth')
    .in('user_id', ids);
  if (!subs || subs.length === 0) return new Response('no subscription', { status: 200 });

  let body = `${rs(inv.grand_total)} ki khareedari  •  ${inv.invoice_no}`;
  if (inv.new_amount != null && Number(inv.new_amount) > 0) {
    body += `\nBaqaya: ${rs(inv.new_amount)}`;
  }
  const payload = JSON.stringify({
    title: 'Jan Ghani Mart',
    body,
    tag: String(inv.invoice_id ?? inv.invoice_no),
    url: '/',
  });

  const dead: string[] = [];
  await Promise.all(subs.map(async (s: { id: string; endpoint: string; p256dh: string; auth: string }) => {
    try {
      await webpush.sendNotification(
        { endpoint: s.endpoint, keys: { p256dh: s.p256dh, auth: s.auth } },
        payload,
      );
    } catch (e) {
      const code = (e as { statusCode?: number }).statusCode;
      if (code === 404 || code === 410) dead.push(s.id); // unsubscribed
      else console.error('push failed', code, (e as Error).message);
    }
  }));

  if (dead.length) {
    await sb.from('customer_push_subscriptions').delete().in('id', dead);
  }
  return new Response(JSON.stringify({ sent: subs.length - dead.length }), { status: 200 });
});
