// Dart se call hone wala chhota helper: window.janGhaniPush
(function () {
  function b64ToUint8(b64) {
    const pad = '='.repeat((4 - (b64.length % 4)) % 4);
    const raw = atob((b64 + pad).replace(/-/g, '+').replace(/_/g, '/'));
    return Uint8Array.from(raw, (c) => c.charCodeAt(0));
  }
  async function reg() {
    return navigator.serviceWorker.register('push-sw.js', { scope: './push/' });
  }
  window.janGhaniPush = {
    supported: function () {
      return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
    },
    permission: function () { return Notification.permission; },
    // Subscription ka JSON string, ya '' agar ijazat nahi mili
    subscribe: async function (vapidKey) {
      const perm = await Notification.requestPermission();
      if (perm !== 'granted') return '';
      const r = await reg();
      await navigator.serviceWorker.ready;
      let sub = await r.pushManager.getSubscription();
      if (!sub) {
        sub = await r.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: b64ToUint8(vapidKey),
        });
      }
      return JSON.stringify(sub.toJSON());
    },
    current: async function () {
      if (!this.supported()) return '';
      const r = await navigator.serviceWorker.getRegistration('./push/');
      const sub = r ? await r.pushManager.getSubscription() : null;
      return sub ? JSON.stringify(sub.toJSON()) : '';
    },
    // Endpoint wapas deta hai (DB se hatane ke liye), '' agar kuch nahi tha
    unsubscribe: async function () {
      const r = await navigator.serviceWorker.getRegistration('./push/');
      const sub = r ? await r.pushManager.getSubscription() : null;
      if (!sub) return '';
      const ep = sub.endpoint;
      await sub.unsubscribe();
      return ep;
    },
  };
})();
