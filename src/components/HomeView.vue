<script setup>
import { ref } from "vue";
import { PLAYERS } from "../data/decks";
import { DECKS, MIX, store, cardKeys, completedCount, addQuestion } from "../store";

defineEmits(["select", "back"]);

const showHelp = ref(false);
const addDeck = ref(DECKS[0].id);
const addText = ref("");

const seen = (deck) => completedCount(deck);

function submit() {
  const text = addText.value.trim();
  if (!text) return;
  addQuestion(addDeck.value, text);
  addText.value = "";
}
</script>

<template>
  <main class="home">
    <button class="icon back" aria-label="Back" @click="$emit('back')">&larr;</button>
    <header class="top">
      <h1>Get2know</h1>
      <p class="sub">for {{ PLAYERS[0] }} &amp; {{ PLAYERS[1] }}</p>
      <p class="lead">Flip through the cards and answer together to get to know each other even better.</p>
    </header>

    <button class="tile mix" :style="{ '--c': MIX.color }" @click="$emit('select', MIX)">
      <span class="emoji">{{ MIX.emoji }}</span>
      <span class="text">
        <span class="name">{{ MIX.name }}</span>
        <span class="desc">{{ cardKeys(MIX).length - completedCount(MIX) }} unanswered cards across every category</span>
      </span>
    </button>

    <h2>or pick a deck</h2>
    <div class="grid">
      <button v-for="d in DECKS" :key="d.id" class="tile" :style="{ '--c': d.color }" @click="$emit('select', d)">
        <span class="emoji">{{ d.emoji }}</span>
        <span class="name">{{ d.name }}</span>
        <span class="desc">{{ d.desc }}</span>
        <span class="count">{{ seen(d) }} / {{ cardKeys(d).length }}</span>
      </button>
    </div>

    <footer>
      <button class="link" @click="showHelp = true">how it works</button>
      <details>
        <summary>add your own question</summary>
        <form @submit.prevent="submit">
          <select v-model="addDeck" aria-label="Deck">
            <option v-for="d in DECKS" :key="d.id" :value="d.id">{{ d.name }}</option>
          </select>
          <textarea v-model="addText" rows="2" maxlength="200" placeholder="your question..." required />
          <button type="submit" class="btn">add card</button>
        </form>
      </details>
    </footer>

    <div v-if="showHelp" class="overlay" @click.self="showHelp = false">
      <div class="modal">
        <h2>how it works</h2>
        <p>Pick a deck, or The Mix for a bit of everything.</p>
        <p>Read the card out loud and <b>both</b> answer. The card tells you who goes first.</p>
        <p>Tap the card or swipe left to draw the next one, swipe right to go back. We remember where you stopped.</p>
        <button class="btn" @click="showHelp = false">got it</button>
      </div>
    </div>
  </main>
</template>
