import { ref } from "vue";
import { supabase } from "./supabase";

export const session = ref(null);
export const authReady = ref(false);

let versionCheck;
async function checkForAppUpdate() {
  if (!import.meta.env.PROD || !supabase || typeof window === "undefined" || versionCheck) return versionCheck;
  versionCheck = (async () => {
    try {
      const versionUrl = new URL(`${import.meta.env.BASE_URL}version.json`, window.location.origin);
      versionUrl.searchParams.set("_", String(Date.now()));
      const response = await fetch(versionUrl, { cache: "no-store" });
      if (!response.ok) return;
      const deployed = await response.json();
      if (!deployed.version || deployed.version === __APP_VERSION__) return;
      const currentUrl = new URL(window.location.href);
      currentUrl.searchParams.set("v", deployed.version.slice(0, 8));
      window.location.replace(currentUrl.toString());
    } catch {
      // Keep the current app usable when the version endpoint is unavailable.
    }
  })().finally(() => { versionCheck = null; });
  return versionCheck;
}

if (supabase) {
  supabase.auth.getSession().then(({ data }) => {
    session.value = data.session;
    authReady.value = true;
    if (data.session) void checkForAppUpdate();
  }).catch(() => { authReady.value = true; });

  supabase.auth.onAuthStateChange((event, nextSession) => {
    session.value = nextSession;
    if (event === "SIGNED_IN" && nextSession) void checkForAppUpdate();
  });
} else {
  authReady.value = true;
}

export const signIn = (email, password, captchaToken) => supabase.auth.signInWithPassword({
  email,
  password,
  ...(captchaToken ? { options: { captchaToken } } : {})
});
export const signOut = () => supabase.auth.signOut();
