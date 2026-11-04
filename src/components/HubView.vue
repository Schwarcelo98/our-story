<script setup>
import { PLAYERS } from "../data/decks";
import StoryArt from "./StoryArt.vue";

defineEmits(["open"]);

// Add new features here as extra entries.
const sections = [
  { screen: "decks", emoji: "💬", name: "Get2know", desc: "question cards to learn more about each other", color: "#ff8a65" },
  { screen: "album", emoji: "📸", name: "Our Album", desc: "photos and notes of our story", color: "#8ecae6" }
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
