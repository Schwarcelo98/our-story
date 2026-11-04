import { reactive, watch } from "vue";
import { supabase } from "./supabase";
import { session } from "./auth";
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

let syncTimer;
let loadingShared = false;
watch(store, () => {
  localStorage.setItem(KEY, JSON.stringify(store));
  if (!session.value || loadingShared || !supabase) return;
  clearTimeout(syncTimer);
  syncTimer = setTimeout(async () => {
    const { error } = await supabase.from("shared_state").upsert({ id: "couple", data: { progress: store.progress, custom: store.custom } });
    if (error) console.error("Could not sync shared story progress", error);
  }, 400);
}, { deep: true });

export async function loadSharedState() {
  if (!supabase) return;
  const { data, error } = await supabase.from("shared_state").select("data").eq("id", "couple").maybeSingle();
  if (error) throw error;
  if (data?.data) {
    loadingShared = true;
    store.progress = data.data.progress || {};
    store.custom = data.data.custom || {};
    loadingShared = false;
  } else {
    await supabase.from("shared_state").upsert({ id: "couple", data: { progress: store.progress, custom: store.custom } });
  }
}

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
