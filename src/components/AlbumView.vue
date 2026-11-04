<script setup>
import { ref, reactive } from "vue";
import { entries, loadAlbum, saveEntry, removeEntry, resizeImage } from "../album";

defineEmits(["back"]);

const mode = ref(null); // null | "view" | "edit"
const viewing = ref(null);
const busy = ref(false);
const loading = ref(false);
const error = ref("");
const loadError = ref("");
const draft = reactive({ id: null, title: "", date: "", note: "", photo: null, photoPath: null, preview: null });

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

function startEdit(entry) {
  Object.assign(draft, entry
    ? { id: entry.id, title: entry.title, date: entry.date, note: entry.note, photo: null, photoPath: entry.photo_path, preview: entry.url }
    : { id: null, title: "", date: today(), note: "", photo: null, photoPath: null, preview: null });
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
      <p class="lead">Photos and notes of our story.</p>
      <button class="btn" @click="startEdit()">+ add a memory</button>
    </header>

    <p v-if="loadError" class="error">{{ loadError }}</p>
    <p v-else-if="loading && !entries.length" class="empty">loading...</p>
    <p v-else-if="!entries.length" class="empty">Nothing here yet. Add your first photo or note.</p>

    <div class="polaroids">
      <button v-for="e in entries" :key="e.id" class="polaroid" @click="open(e)">
        <img v-if="e.url" :src="e.url" :alt="e.title || 'Photo'" loading="lazy">
        <span v-else class="noteblock">{{ e.note }}</span>
        <span class="cap">{{ e.title || "untitled" }}</span>
        <span class="date">{{ pretty(e.date) }}</span>
      </button>
    </div>

    <div v-if="mode === 'view'" class="overlay" @click.self="close">
      <div class="modal wide">
        <img v-if="viewing.url" :src="viewing.url" :alt="viewing.title" class="full">
        <h2>{{ viewing.title || "untitled" }}</h2>
        <p class="date">{{ pretty(viewing.date) }}</p>
        <p v-if="viewing.note" class="note">{{ viewing.note }}</p>
        <div class="row">
          <button class="btn ghost" @click="close">close</button>
          <button class="btn" @click="startEdit(viewing)">edit</button>
        </div>
      </div>
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
