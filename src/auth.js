import { ref } from "vue";
import { supabase } from "./supabase";

export const session = ref(null);
export const authReady = ref(false);

if (supabase) {
  supabase.auth.getSession().then(({ data }) => {
    session.value = data.session;
    authReady.value = true;
  });
  supabase.auth.onAuthStateChange((_event, s) => {
    session.value = s;
  });
}

export const signIn = (email, password) => supabase.auth.signInWithPassword({ email, password });
export const signOut = () => supabase.auth.signOut();
