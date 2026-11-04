<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from "vue";
import { PLAYERS } from "../data/decks";
import { store, cardKeys, completedCount, makeOrder, markCompleted, resolveCard } from "../store";

const props = defineProps({ deck: { type: Object, required: true } });
defineEmits(["back"]);

const total = cardKeys(props.deck).length;
const saved = store.progress[props.deck.id];
const valid = saved?.order?.length && saved.order.every(resolveCard) && saved.pos < saved.order.length;

const order = ref(valid ? [...saved.order] : makeOrder(props.deck));
const pos = ref(valid ? Math.min(saved.pos, total - 1) : 0);
const dir = ref(1);

const card = computed(() => order.value.length ? resolveCard(order.value[pos.value]) : null);
const isCompleted = computed(() => Boolean(order.value[pos.value] && store.completed.includes(order.value[pos.value])));
const starter = computed(() => PLAYERS[pos.value % 2]);

watch([order, pos], () => {
  store.progress[props.deck.id] = { order: [...order.value], pos: pos.value };
}, { immediate: true });

function go(delta) {
  if (!card.value) return;
  const n = pos.value + delta;
  if (n < 0) return;
  dir.value = delta;
  if (delta > 0) markCompleted(order.value[pos.value]);
  if (n >= order.value.length) {
    order.value = makeOrder(props.deck);
    pos.value = 0;
  } else {
    pos.value = n;
  }
}

function reshuffle() {
  dir.value = 1;
  order.value = makeOrder(props.deck);
  pos.value = 0;
}

let startX = null;
const onDown = (e) => { startX = e.clientX; };
const onUp = (e) => {
  if (startX === null) return;
  const dx = e.clientX - startX;
  startX = null;
  go(dx > 60 ? -1 : 1);
};

function onKey(e) {
  if (e.key === "ArrowRight") go(1);
  if (e.key === "ArrowLeft") go(-1);
}
onMounted(() => document.addEventListener("keydown", onKey));
onUnmounted(() => document.removeEventListener("keydown", onKey));
</script>

<template>
  <main class="game" :style="{ '--deck': card?.deck.color || deck.color }">
    <header class="bar">
      <button class="icon" aria-label="Back to decks" @click="$emit('back')">&larr;</button>
      <span class="deckname">{{ deck.emoji }} {{ deck.name }}</span>
      <span class="counter">{{ completedCount(deck) }}/{{ total }} done</span>
    </header>

    <div class="stage">
      <div v-if="card" class="stack">
        <Transition :name="dir > 0 ? 'next' : 'prev'" mode="out-in">
          <article :key="order[pos]" class="card" tabindex="0" @pointerdown="onDown" @pointerup="onUp"
            @pointercancel="startX = null">
            <span class="tag">{{ card.deck.emoji }} {{ card.deck.name }}</span>
            <span v-if="isCompleted" class="done-ribbon">Already answered</span>
            <p class="question">{{ card.text }}</p>
            <span class="who">both answer &middot; <b>{{ starter }}</b> goes first</span>
          </article>
        </Transition>
      </div>
      <section v-else class="deck-complete">
        <span class="complete-heart" aria-hidden="true">♥</span>
        <h2>All caught up!</h2>
        <p>You have answered every card in this deck. They will come back after you have gone through all the other cards.</p>
      </section>
    </div>

    <p class="hint">{{ card ? "tap the card for the next question" : "Pick another deck or keep exploring The Mix" }}</p>

    <div class="actions">
      <button class="icon" aria-label="Previous card" :disabled="pos === 0 || !card" @click="go(-1)">&larr;</button>
      <button class="btn" :disabled="!card" @click="go(1)">next card</button>
      <button class="icon" aria-label="Reshuffle remaining cards" title="Reshuffle remaining cards" :disabled="!card" @click="reshuffle">&#8635;</button>
    </div>
  </main>
</template>
