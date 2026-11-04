<script setup>
import { onMounted, onUnmounted, ref } from "vue";
import { signIn } from "../auth";

const captchaSiteKey = import.meta.env.VITE_TURNSTILE_SITE_KEY;
const email = ref("");
const password = ref("");
const error = ref("");
const busy = ref(false);
const captchaHost = ref(null);
const captchaToken = ref("");
const captchaReady = ref(!captchaSiteKey);
let captchaWidget;

onMounted(() => {
  if (!captchaSiteKey) return;
  const renderCaptcha = () => {
    if (!window.turnstile || !captchaHost.value) return;
    captchaWidget = window.turnstile.render(captchaHost.value, {
      sitekey: captchaSiteKey,
      callback: (token) => { captchaToken.value = token; error.value = ""; },
      "expired-callback": () => { captchaToken.value = ""; },
      "error-callback": () => { captchaToken.value = ""; error.value = "Captcha could not load. Please refresh the page."; }
    });
    captchaReady.value = true;
  };
  if (window.turnstile) {
    renderCaptcha();
    return;
  }
  const script = document.createElement("script");
  script.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";
  script.async = true;
  script.onload = renderCaptcha;
  script.onerror = () => { error.value = "Captcha could not load. Please refresh the page."; };
  document.head.appendChild(script);
});

onUnmounted(() => {
  if (captchaWidget && window.turnstile) window.turnstile.remove(captchaWidget);
});

async function submit() {
  if (captchaSiteKey && !captchaToken.value) {
    error.value = "Please complete the captcha first.";
    return;
  }
  busy.value = true;
  error.value = "";
  try {
    const { error: err } = await signIn(email.value.trim(), password.value, captchaToken.value);
    if (err) error.value = "The email address or password is incorrect.";
  } catch {
    error.value = "Unable to log in right now. Please check your connection.";
  } finally {
    busy.value = false;
    if (captchaWidget && captchaHost.value && window.turnstile) {
      window.turnstile.reset(captchaWidget);
      captchaToken.value = "";
    }
  }
}
</script>

<template>
  <main class="home login-page">
    <header class="top">
      <h1>Our Story</h1>
      <p class="sub">Vero &amp; Daniel</p>
      <p class="lead">Log in to open your story together.</p>
    </header>
    <form class="login" @submit.prevent="submit">
      <label class="field">
        Email address
        <input v-model="email" type="email" autocomplete="username" inputmode="email" required>
      </label>
      <label class="field">
        Password
        <input v-model="password" type="password" autocomplete="current-password" required>
      </label>
      <div v-if="captchaSiteKey" ref="captchaHost" class="captcha-box" :aria-busy="!captchaReady"></div>
      <p v-if="error" class="error" role="alert">{{ error }}</p>
      <button type="submit" class="btn" :disabled="busy || !captchaReady">{{ busy ? "Logging in…" : "Log in" }}</button>
    </form>
  </main>
</template>
