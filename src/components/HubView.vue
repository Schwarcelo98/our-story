<script setup>
import { PLAYERS } from "../data/decks";
import { session } from "../auth";
import StoryArt from "./StoryArt.vue";

defineEmits(["open"]);

// The owner can prepare the recap early; it appears to both accounts on reveal day.
const ownerEmail = (import.meta.env.VITE_STORY_OWNER_EMAIL || "").trim().toLowerCase();
const isOwner = Boolean(ownerEmail && session.value?.user?.email?.toLowerCase() === ownerEmail);
const isRevealed = Date.now() >= new Date("2026-11-25T00:00:00+01:00").getTime();
const sections = [
  { screen: "decks", emoji: "💬", name: "Get2know", desc: "question cards to learn more about each other", color: "#ff8a65" },
  { screen: "album", emoji: "📸", name: "Our Album", desc: "photos and notes of our story", color: "#8ecae6" },
  ...((isOwner || isRevealed) ? [{ screen: "recap", emoji: "💌", name: "Our first month", desc: isRevealed ? "a little story of our first month" : "your first month, in little moments", color: "#f4b4bc" }] : [])
];
</script>

<template>
  <main class="home">
    <header class="top">
      <h1>Our Story</h1>
      <p class="sub">{{ PLAYERS[0] }} &amp; {{ PLAYERS[1] }}</p>
      <StoryArt />
      <p class="lead">A little place for everything that belongs to us.</p>
    </header>

    <div class="hub">
      <button v-for="s in sections" :key="s.screen" class="tile mix" :style="{ '--c': s.color }"
        @click="$emit('open', s.screen)">
        <span class="emoji">{{ s.emoji }}</span>
        <span class="text">
          <span class="name">{{ s.name }}</span>
          <span class="desc">{{ s.desc }}</span>
        </span>
      </button>
    </div>
  </main>
</template>
