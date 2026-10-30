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
  const { error: err } = await signIn(email.value.trim(), password.value);
  if (err) error.value = "Wrong email or password.";
  busy.value = false;
}
</script>

<template>
  <form class="login" @submit.prevent="submit">
    <p>The album is private. Please log in.</p>
    <label class="field">
      email
      <input v-model="email" type="email" autocomplete="username" required>
    </label>
    <label class="field">
      password
      <input v-model="password" type="password" autocomplete="current-password" required>
    </label>
    <p v-if="error" class="error">{{ error }}</p>
    <button type="submit" class="btn" :disabled="busy">log in</button>
  </form>
</template>
