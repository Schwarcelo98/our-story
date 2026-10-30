import { reactive, watch } from "vue";
import { DECKS } from "./data/decks";

const KEY = "get2know-v2";

export const MIX = {
  id: "mix",
  name: "The Mix",
  emoji: "🎲",
  color: "#ff8a65",
  desc: "A bit of everything"
};

export const store = reactive({
  progress: {},
  custom: {},
  ...JSON.parse(localStorage.getItem(KEY) || "{}")
});

watch(store, () => localStorage.setItem(KEY, JSON.stringify(store)), { deep: true });

export const allQuestions = (deck) => [...deck.questions, ...(store.custom[deck.id] || [])];

const keysOf = (deck) => allQuestions(deck).map((_, i) => `${deck.id}:${i}`);

export const cardKeys = (deck) => (deck.id === MIX.id ? DECKS.flatMap(keysOf) : keysOf(deck));

// Card keys look like "deckId:index"; progress saved in older formats resolves to null.
export function resolveCard(key) {
  if (typeof key !== "string") return null;
  const [deckId, idx] = key.split(":");
  const deck = DECKS.find((d) => d.id === deckId);
  const text = deck && allQuestions(deck)[Number(idx)];
  return text ? { text, deck } : null;
}

function shuffle(a) {
  a = [...a];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// The mix deals one card per category per round so no category dominates.
export function makeOrder(deck) {
  if (deck.id !== MIX.id) return shuffle(keysOf(deck));
  const piles = DECKS.map((d) => shuffle(keysOf(d)));
  const out = [];
  while (piles.some((p) => p.length)) {
    for (const p of shuffle(piles)) if (p.length) out.push(p.pop());
  }
  return out;
}

export function addQuestion(deckId, text) {
  (store.custom[deckId] ||= []).push(text);
}

export { DECKS };
