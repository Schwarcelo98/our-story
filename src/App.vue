<script setup>
import { ref, watch } from "vue";
import { authReady, session, signOut } from "./auth";
import { configured } from "./supabase";
import LoginView from "./components/LoginView.vue";
import { loadSharedState } from "./store";
import HubView from "./components/HubView.vue";
import HomeView from "./components/HomeView.vue";
import GameView from "./components/GameView.vue";
import AlbumView from "./components/AlbumView.vue";

const screen = ref("hub"); // hub | decks | game | album
const deck = ref(null);

watch(session, async (nextSession) => {
  if (nextSession) {
    try { await loadSharedState(); }
    catch (error) { console.error("Could not load shared story progress", error); }
  }
}, { immediate: true });

function pick(d) {
  deck.value = d;
  screen.value = "game";
}
</script>

<template>
  <main v-if="!configured" class="home"><h1>Our Story</h1><p class="error">Supabase is not configured yet. Add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY to your GitHub Actions secrets.</p></main>
  <main v-else-if="!authReady" class="home"><h1>Our Story</h1><p class="empty">Loading…</p></main>
  <LoginView v-else-if="!session" />
  <template v-else>
    <button class="link logout" @click="signOut">Log out</button>
    <HubView v-if="screen === 'hub'" @open="screen = $event" />
    <HomeView v-else-if="screen === 'decks'" @select="pick" @back="screen = 'hub'" />
    <GameView v-else-if="screen === 'game'" :key="deck.id" :deck="deck" @back="screen = 'decks'" />
    <AlbumView v-else @back="screen = 'hub'" />
  </template>
</template>
