<script setup>
import { ref } from "vue";
import { signIn } from "../auth";

const email = ref("");
const password = ref("");
const error = ref("");
const busy = ref(false);

async function submit() {
  busy.value = true;
  error.value = "";
  try {
    const { error: err } = await signIn(email.value.trim(), password.value);
    if (err) error.value = "The email address or password is incorrect.";
  } catch {
    error.value = "Unable to log in right now. Please check your connection.";
  } finally {
    busy.value = false;
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
      <p v-if="error" class="error" role="alert">{{ error }}</p>
      <button type="submit" class="btn" :disabled="busy">{{ busy ? "Logging in…" : "Log in" }}</button>
    </form>
  </main>
</template>
