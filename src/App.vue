<script setup>
import { ref } from "vue";
import HubView from "./components/HubView.vue";
import HomeView from "./components/HomeView.vue";
import GameView from "./components/GameView.vue";
import AlbumView from "./components/AlbumView.vue";

const screen = ref("hub"); // hub | decks | game | album
const deck = ref(null);

function pick(d) {
  deck.value = d;
  screen.value = "game";
}
</script>

<template>
  <HubView v-if="screen === 'hub'" @open="screen = $event" />
  <HomeView v-else-if="screen === 'decks'" @select="pick" @back="screen = 'hub'" />
  <GameView v-else-if="screen === 'game'" :key="deck.id" :deck="deck" @back="screen = 'decks'" />
  <AlbumView v-else @back="screen = 'hub'" />
</template>
