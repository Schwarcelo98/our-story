import { ref } from "vue";
import { supabase } from "./supabase";

export const session = ref(null);
export const authReady = ref(false);

if (supabase) {
  supabase.auth.getSession().then(({ data }) => {
    session.value = data.session;
    authReady.value = true;
  }).catch(() => { authReady.value = true; });

  supabase.auth.onAuthStateChange((_event, nextSession) => {
    session.value = nextSession;
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
