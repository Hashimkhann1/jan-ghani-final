// Customer ki wasooli (installment) par manager/accountant/owner ko PWA push.
// Trigger: public.fn_notify_installment_payment
// (2026_11_07_installment_push_notifications.sql)
//
// Deploy:  supabase functions deploy notify-installment --no-verify-jwt
// Secrets notify-sale wale hi (VAPID_*, WEBHOOK_SECRET).

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

  const p = await req.json();
  if (!p?.store_id) return new Response('no store', { status: 200 });

  // Receivers: owner + accountant (sab), manager (sirf is branch ka)
  const { data: staff } = await sb
    .from('users')
    .select('id, role, branch_id')
    .in('role', ['owner', 'accountant', 'manager']);
  const ids = (staff ?? [])
    .filter((u: { role: string; branch_id: string | null }) =>
      u.role !== 'manager' || String(u.branch_id) === String(p.store_id))
    .map((u: { id: string }) => u.id);
  if (ids.length === 0) return new Response('no receivers', { status: 200 });

  const { data: subs } = await sb
    .from('customer_push_subscriptions')
    .select('id, endpoint, p256dh, auth')
    .in('user_id', ids);
  if (!subs || subs.length === 0) return new Response('no subscription', { status: 200 });

  const { data: branch } = await sb
    .from('branch').select('name').eq('id', p.store_id).maybeSingle();

  const who = p.customer_name || 'Customer';
  let body = `${who} ne ${rs(p.pay_amount)} installment mein diye`;
  if (branch?.name) body += `  •  ${branch.name}`;
  if (p.new_amount != null) body += `\nBaqaya: ${rs(p.new_amount)}`;

  const payload = JSON.stringify({
    title: 'Installment received',
    body,
    tag: `ledger-${p.ledger_id}`,
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
      if (code === 404 || code === 410) dead.push(s.id);
      else console.error('push failed', code, (e as Error).message);
    }
  }));

  if (dead.length) {
    await sb.from('customer_push_subscriptions').delete().in('id', dead);
  }
  return new Response(JSON.stringify({ sent: subs.length - dead.length }), { status: 200 });
});
