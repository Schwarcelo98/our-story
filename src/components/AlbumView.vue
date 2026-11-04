<script setup>
import { ref, reactive, computed, watch, onMounted, onUnmounted } from "vue";
import { entries, loadAlbum, saveEntry, removeEntry, resizeImage } from "../album";

defineEmits(["back"]);

const mode = ref(null); // null | "view" | "edit"
const viewing = ref(null);
const zoomed = ref(false);
const search = ref("");
const sortOrder = ref("desc");
const visibleLimit = ref(12);
const scrollSentinel = ref(null);
const supportsIntersectionObserver = typeof window !== "undefined" && "IntersectionObserver" in window;
const busy = ref(false);
const loading = ref(false);
const error = ref("");
const loadError = ref("");
const draft = reactive({ id: null, title: "", date: "", location: "", note: "", photo: null, photoPath: null, preview: null });
const filteredEntries = computed(() => {
  const term = search.value.trim().toLowerCase();
  const matching = term
    ? entries.value.filter((entry) => [entry.title, entry.location, entry.note, entry.date].some((value) => value?.toLowerCase().includes(term)))
    : [...entries.value];
  return matching.sort((a, b) => {
    const dateOrder = a.date.localeCompare(b.date) || String(a.created_at).localeCompare(String(b.created_at));
    return sortOrder.value === "asc" ? dateOrder : -dateOrder;
  });
});
const visibleEntries = computed(() => filteredEntries.value.slice(0, visibleLimit.value));
const hasMoreToShow = computed(() => visibleEntries.value.length < filteredEntries.value.length);
const photoEntries = computed(() => filteredEntries.value.filter((entry) => entry.url));
const currentPhotoIndex = computed(() => photoEntries.value.findIndex((entry) => entry.id === viewing.value?.id));

const today = () => new Date().toLocaleDateString("sv-SE");
const pretty = (d) => new Date(`${d}T00:00`).toLocaleDateString("en-GB", { day: "numeric", month: "long", year: "numeric" });

async function load() {
  loading.value = true;
  loadError.value = "";
  try {
    await loadAlbum();
  } catch {
    loadError.value = "Could not load the album. Please try again.";
  } finally {
    loading.value = false;
  }
}

load();

watch([search, sortOrder], () => { visibleLimit.value = 12; });

function revealMore() {
  if (hasMoreToShow.value) visibleLimit.value = Math.min(visibleLimit.value + 12, filteredEntries.value.length);
}

function startEdit(entry) {
  Object.assign(draft, entry
    ? { id: entry.id, title: entry.title, date: entry.date, location: entry.location || "", note: entry.note, photo: null, photoPath: entry.photo_path, preview: entry.url }
    : { id: null, title: "", date: today(), location: "", note: "", photo: null, photoPath: null, preview: null });
  error.value = "";
  mode.value = "edit";
}

function open(entry) {
  viewing.value = entry;
  mode.value = "view";
}

function close() {
  mode.value = null;
  viewing.value = null;
  zoomed.value = false;
}

function onKey(e) {
  if (e.key === "Escape") {
    if (zoomed.value) zoomed.value = false;
    else if (mode.value) close();
  }
  if (!zoomed.value || photoEntries.value.length < 2) return;
  if (e.key === "ArrowLeft") { e.preventDefault(); navigatePhoto(-1); }
  if (e.key === "ArrowRight") { e.preventDefault(); navigatePhoto(1); }
}
let scrollObserver;
onMounted(() => {
  document.addEventListener("keydown", onKey);
  if (supportsIntersectionObserver && scrollSentinel.value) {
    scrollObserver = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) revealMore();
    }, { rootMargin: "360px 0px" });
    scrollObserver.observe(scrollSentinel.value);
  }
});
onUnmounted(() => {
  document.removeEventListener("keydown", onKey);
  scrollObserver?.disconnect();
});

function navigatePhoto(direction) {
  const photos = photoEntries.value;
  if (photos.length < 2) return;
  const index = currentPhotoIndex.value;
  viewing.value = photos[(index + direction + photos.length) % photos.length];
}

let swipeStartX = null;
function onPhotoPointerDown(e) { swipeStartX = e.clientX; }
function onPhotoPointerUp(e) {
  if (swipeStartX === null) return;
  const delta = e.clientX - swipeStartX;
  swipeStartX = null;
  if (Math.abs(delta) > 55) navigatePhoto(delta < 0 ? 1 : -1);
}

async function onFile(e) {
  const file = e.target.files[0];
  if (!file) return;
  busy.value = true;
  error.value = "";
  try {
    draft.photo = await resizeImage(file);
    draft.preview = URL.createObjectURL(draft.photo);
  } catch {
    error.value = "This image format is not supported. Try a JPG or PNG.";
  } finally {
    busy.value = false;
    e.target.value = "";
  }
}

async function save() {
  if (!draft.photo && !draft.photoPath && !draft.title.trim() && !draft.note.trim()) {
    error.value = "Add a photo, a title or a note first.";
    return;
  }
  busy.value = true;
  try {
    await saveEntry({ ...draft, title: draft.title.trim(), note: draft.note.trim() });
    close();
  } catch {
    error.value = "Could not save. Please try again.";
  } finally {
    busy.value = false;
  }
}

async function remove() {
  if (!confirm("Delete this memory?")) return;
  try {
    await removeEntry({ id: draft.id, photoPath: draft.photoPath });
    close();
  } catch {
    error.value = "Could not delete. Please try again.";
  }
}
</script>

<template>
  <main class="home album">
    <button class="icon back" aria-label="Back" @click="$emit('back')">&larr;</button>

    <header class="top">
      <h1>Our Album</h1>
      <p class="lead">Photos and notes from our story.</p>
      <button class="btn" @click="startEdit()">+ add a memory</button>
    </header>

    <div class="album-controls">
      <label class="album-search">
        <span aria-hidden="true">⌕</span>
        <input v-model="search" type="search" aria-label="Search memories" placeholder="Search by title, place or note…">
        <button v-if="search" type="button" aria-label="Clear search" @click="search = ''">×</button>
      </label>
      <label class="sort-control">
        <span>Sort by date</span>
        <select v-model="sortOrder" aria-label="Sort memories by date">
          <option value="desc">Newest first</option>
          <option value="asc">Oldest first</option>
        </select>
      </label>
    </div>

    <p v-if="loadError" class="error">{{ loadError }}</p>
    <p v-else-if="loading && !entries.length" class="empty">loading...</p>
    <p v-else-if="!entries.length" class="empty">Nothing here yet. Add your first photo or note.</p>
    <p v-else-if="!filteredEntries.length" class="empty">No memories match your search.</p>

    <div class="polaroids">
      <button v-for="e in visibleEntries" :key="e.id" class="polaroid" @click="open(e)">
        <img v-if="e.url" :src="e.url" :alt="e.title || 'Photo'" loading="lazy">
        <span v-else class="noteblock">{{ e.note }}</span>
        <span class="cap">{{ e.title || "untitled" }}</span>
        <span class="date">{{ pretty(e.date) }}</span>
        <span v-if="e.location" class="place">{{ e.location }}</span>
      </button>
    </div>

    <div ref="scrollSentinel" class="scroll-sentinel" aria-live="polite">
      <p v-if="hasMoreToShow">Keep scrolling for more memories…</p>
      <p v-else-if="filteredEntries.length">You’ve reached the end of your memories.</p>
      <button v-if="hasMoreToShow && !supportsIntersectionObserver" class="btn ghost" @click="revealMore">Load more</button>
    </div>

    <div v-if="mode === 'view'" class="overlay" @click.self="close">
      <div class="modal wide">
        <button v-if="viewing.url" class="photo-zoom" type="button" aria-label="Enlarge photo" @click="zoomed = true">
          <img :src="viewing.url" :alt="viewing.title || 'Memory photo'" class="full">
          <span class="zoom-hint">Tap to enlarge</span>
        </button>
        <h2>{{ viewing.title || "untitled" }}</h2>
        <p class="date">{{ pretty(viewing.date) }}</p>
        <p v-if="viewing.location" class="place">{{ viewing.location }}</p>
        <p v-if="viewing.note" class="note">{{ viewing.note }}</p>
        <div class="row">
          <button class="btn ghost" @click="close">close</button>
          <button class="btn" @click="startEdit(viewing)">edit</button>
        </div>
      </div>
    </div>

    <div v-if="zoomed && viewing?.url" class="photo-lightbox" role="dialog" aria-modal="true" aria-label="Enlarged memory photo" @click.self="zoomed = false">
      <button class="icon lightbox-close" aria-label="Close enlarged photo" @click="zoomed = false">×</button>
      <div class="lightbox-gallery" @pointerdown="onPhotoPointerDown" @pointerup="onPhotoPointerUp" @pointercancel="swipeStartX = null">
        <button v-if="photoEntries.length > 1" class="icon lightbox-nav lightbox-prev" aria-label="Previous photo" @click="navigatePhoto(-1)">&larr;</button>
        <img :src="viewing.url" :alt="viewing.title || 'Memory photo'" class="lightbox-image">
        <button v-if="photoEntries.length > 1" class="icon lightbox-nav lightbox-next" aria-label="Next photo" @click="navigatePhoto(1)">&rarr;</button>
      </div>
      <p v-if="photoEntries.length > 1" class="lightbox-count">{{ currentPhotoIndex + 1 }} / {{ photoEntries.length }}</p>
      <p v-if="viewing.title" class="lightbox-caption">{{ viewing.title }}</p>
    </div>

    <div v-if="mode === 'edit'" class="overlay" @click.self="close">
      <form class="modal wide" @submit.prevent="save">
        <h2>{{ draft.id ? "edit memory" : "new memory" }}</h2>

        <img v-if="draft.preview" :src="draft.preview" alt="Preview" class="full">
        <label class="field">
          photo
          <input type="file" accept="image/*" :disabled="busy" @change="onFile">
        </label>
        <label class="field">
          title
          <input v-model="draft.title" maxlength="80" placeholder="our first trip...">
        </label>
        <label class="field">
          date
          <input v-model="draft.date" type="date" required>
        </label>
        <label class="field">
          location
          <input v-model="draft.location" maxlength="120" placeholder="Vienna, Austria">
        </label>
        <label class="field">
          note
          <textarea v-model="draft.note" rows="5" maxlength="2000" placeholder="what do you remember?" />
        </label>

        <p v-if="error" class="error">{{ error }}</p>

        <div class="row">
          <button v-if="draft.id" type="button" class="btn danger" @click="remove">delete</button>
          <button type="button" class="btn ghost" @click="close">cancel</button>
          <button type="submit" class="btn" :disabled="busy">save</button>
        </div>
      </form>
    </div>
  </main>
</template>
