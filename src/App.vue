<script setup>
import { computed, ref, watch, onMounted, onUnmounted } from "vue";
import { authReady, session, signOut } from "./auth";
import { configured } from "./supabase";
import LoginView from "./components/LoginView.vue";
import { loadSharedState } from "./store";
import HubView from "./components/HubView.vue";
import HomeView from "./components/HomeView.vue";
import GameView from "./components/GameView.vue";
import AlbumView from "./components/AlbumView.vue";
import MonthRecapView from "./components/MonthRecapView.vue";

const screen = ref("hub"); // hub | decks | game | album | recap
const deck = ref(null);
const pageLoading = ref(false);
const loggedInName = computed(() => {
  const email = session.value?.user?.email?.trim().toLowerCase();
  if (email === "veronicagodea387@gmail.com") return "Vero";
  if (email === "daniel.schwarzer@gmx.at") return "Dani";
  return session.value?.user?.email || "there";
});
const recapOwnerEmail = (import.meta.env.VITE_STORY_OWNER_EMAIL || "").trim().toLowerCase();
const canOpenRecap = () => Boolean(
  session.value?.user?.email?.trim().toLowerCase() === recapOwnerEmail
  || Date.now() >= new Date("2026-11-25T00:00:00+01:00").getTime()
);
let pageTimer;

watch(screen, () => {
  pageLoading.value = true;
  clearTimeout(pageTimer);
  pageTimer = setTimeout(() => { pageLoading.value = false; }, 420);
});

watch(session, async (nextSession) => {
  if (nextSession) {
    try { await loadSharedState(); }
    catch (error) { console.error("Could not load shared story progress", error); }
    if (window.location.hash === "#recap" && canOpenRecap()) screen.value = "recap";
  } else if (screen.value === "recap") {
    screen.value = "hub";
  }
}, { immediate: true });

function openSection(target) {
  if (target === "recap" && !canOpenRecap()) return;
  if (target === "recap") window.location.hash = "recap";
  else if (window.location.hash) window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}`);
  screen.value = target;
}

function backToHub() {
  if (window.location.hash) window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}`);
  screen.value = "hub";
}

function syncRecapHash() {
  if (window.location.hash === "#recap") {
    if (session.value && canOpenRecap()) screen.value = "recap";
  } else if (screen.value === "recap") {
    screen.value = "hub";
  }
}
onMounted(() => window.addEventListener("hashchange", syncRecapHash));
onUnmounted(() => window.removeEventListener("hashchange", syncRecapHash));

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
    <button class="logout-button" @click="signOut">
      <span class="logout-heart" aria-hidden="true">♡</span>
      <span class="logged-in-greeting">Hi, {{ loggedInName }}!</span>
      <span>Log out</span>
      <span class="logout-sparkle" aria-hidden="true">✦</span>
    </button>
    <Transition name="page" mode="out-in">
      <HubView v-if="screen === 'hub'" key="hub" @open="openSection" />
      <HomeView v-else-if="screen === 'decks'" key="decks" @select="pick" @back="screen = 'hub'" />
      <GameView v-else-if="screen === 'game'" :key="`game-${deck.id}`" :deck="deck" @back="screen = 'decks'" />
      <AlbumView v-else-if="screen === 'album'" key="album" @back="screen = 'hub'" />
      <MonthRecapView v-else key="recap" @back="backToHub" />
    </Transition>
    <Transition name="heart-loader">
      <div v-if="pageLoading" class="page-loader" role="status" aria-live="polite">
        <span class="loader-heart" aria-hidden="true">♥</span>
        <span>turning our pages…</span>
      </div>
    </Transition>
  </template>
</template>
