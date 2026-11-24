<script setup>
import { computed, ref, reactive, onMounted, onUnmounted, nextTick } from "vue";
import { firstMonth } from "../data/firstMonth";
import { recapEntries, loadRecapMemories, saveRecapMemory, removeRecapMemory, resizeImage } from "../album";
import { session } from "../auth";

defineEmits(["back"]);

const ownerEmail = (import.meta.env.VITE_STORY_OWNER_EMAIL || "").trim().toLowerCase();
const isOwner = Boolean(ownerEmail && session.value?.user?.email?.toLowerCase() === ownerEmail);
const photosByMoment = computed(() => Object.fromEntries(firstMonth.memories.map((memory) => [
  memory.id,
  recapEntries.value.filter((photo) => photo.moment_id === memory.id || (!photo.moment_id && photo.date === memory.date))
])));
const extraPhotos = computed(() => recapEntries.value.filter((photo) =>
  !firstMonth.memories.some((memory) => photo.moment_id === memory.id || (!photo.moment_id && photo.date === memory.date))
));
const galleryIndexes = reactive({});
const touchStarts = {};
const daysBetween = Math.round((Date.parse("2026-10-25T00:00:00Z") - Date.parse("2026-10-04T00:00:00Z")) / 86400000);
const stats = [
  { value: "1", label: "month together" },
  { value: String(daysBetween), label: "days between our first date and becoming a couple" },
  { value: String(firstMonth.memories.length), label: "special moments in our timeline" },
  { value: "1", label: "first weekend getaway" },
  { value: "1", label: "four-legged travel buddy · Benny" },
  { value: "18", label: "days together" },
  { value: "∞", label: "kisses" }
];

const draft = reactive({ moment_id: firstMonth.memories[0].id, title: "", date: firstMonth.memories[0].date, note: "", file: null });
const saving = ref(false);
const deleting = ref("");
const error = ref("");

function photoAt(momentId) {
  const photos = photosByMoment.value[momentId] || [];
  return photos[galleryIndexes[momentId] || 0] || null;
}
function movePhoto(momentId, direction) {
  const count = photosByMoment.value[momentId]?.length || 0;
  if (!count) return;
  galleryIndexes[momentId] = ((galleryIndexes[momentId] || 0) + direction + count) % count;
}
function touchStart(event, momentId) { touchStarts[momentId] = event.changedTouches[0]?.clientX || 0; }
function touchEnd(event, momentId) {
  const delta = (event.changedTouches[0]?.clientX || 0) - (touchStarts[momentId] || 0);
  if (Math.abs(delta) > 45) movePhoto(momentId, delta < 0 ? 1 : -1);
}

function onCarouselKey(event, momentId) {
  if (event.key === "ArrowLeft") { event.preventDefault(); movePhoto(momentId, -1); }
  if (event.key === "ArrowRight") { event.preventDefault(); movePhoto(momentId, 1); }
}

function selectMoment() {
  const moment = firstMonth.memories.find((item) => item.id === draft.moment_id);
  if (moment) draft.date = moment.date;
}
function pickPhoto(event) { draft.file = event.target.files?.[0] || null; }
async function addPhoto() {
  if (!draft.file) return;
  saving.value = true; error.value = "";
  try {
    const photo = await resizeImage(draft.file);
    await saveRecapMemory({ ...draft, photo });
    draft.title = ""; draft.note = ""; draft.file = null;
    const input = document.querySelector("#recap-photo-input");
    if (input) input.value = "";
  } catch (cause) { error.value = cause?.message || "The photo could not be saved."; }
  finally { saving.value = false; }
}
async function deletePhoto(memory) {
  if (!window.confirm(`Delete “${memory.title || "this photo"}” from the recap?`)) return;
  deleting.value = memory.id; error.value = "";
  try {
    await removeRecapMemory({ id: memory.id, photoPath: memory.photo_path });
    const momentId = memory.moment_id || firstMonth.memories.find((item) => item.date === memory.date)?.id;
    if (momentId) galleryIndexes[momentId] = Math.min(galleryIndexes[momentId] || 0, Math.max(0, (photosByMoment.value[momentId]?.length || 1) - 1));
  }
  catch (cause) { error.value = cause?.message || "The photo could not be deleted."; }
  finally { deleting.value = ""; }
}

onMounted(async () => {
  try { await loadRecapMemories(); }
  catch (cause) { error.value = cause?.message || "The recap photos could not be loaded."; }
  await nextTick();
  if ("IntersectionObserver" in window && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    const observer = new IntersectionObserver((items) => items.forEach((item) => {
      if (item.isIntersecting) { item.target.classList.add("is-visible"); observer.unobserve(item.target); }
    }), { threshold: 0.12 });
    document.querySelectorAll(".timeline-item, .stat-card, .recap-closing").forEach((item) => observer.observe(item));
  } else {
    document.querySelectorAll(".timeline-item, .stat-card, .recap-closing").forEach((item) => item.classList.add("is-visible"));
  }
});

onUnmounted(() => { for (const key of Object.keys(touchStarts)) delete touchStarts[key]; });
</script>

<template>
  <main id="recap" class="home recap-page">
    <button class="icon back" aria-label="Back" @click="$emit('back')">&larr;</button>

    <header class="recap-hero">
      <span class="recap-eyebrow">Vero &amp; Daniel · Our first chapter</span>
      <h1>{{ firstMonth.title }}</h1>
      <p class="recap-date-range">{{ firstMonth.dates }}</p>
      <p class="recap-subtitle">{{ firstMonth.subtitle }}</p>
      <div class="recap-divider" aria-hidden="true"><span>✦</span><i></i><span>♡</span><i></i><span>✦</span></div>
      <p class="recap-intro">{{ firstMonth.introduction }}</p>
    </header>

    <section class="timeline-section" aria-labelledby="timeline-title">
      <div class="section-heading">
        <span class="recap-eyebrow">Little moments, a big beginning</span>
        <h2 id="timeline-title">Our Story</h2>
      </div>
      <ol class="recap-timeline">
        <li v-for="memory in firstMonth.memories" :key="memory.id" class="timeline-item" :class="{ featured: memory.featured }">
          <span class="timeline-marker" aria-hidden="true">{{ memory.featured ? "♥" : "✦" }}</span>
          <article class="memory-card">
            <div v-if="photosByMoment[memory.id]?.length" class="memory-carousel"
              tabindex="0" :aria-label="`Photos for ${memory.title}`"
              @keydown="onCarouselKey($event, memory.id)"
              @touchstart.passive="touchStart($event, memory.id)" @touchend.passive="touchEnd($event, memory.id)">
              <Transition name="photo-slide" mode="out-in">
                <figure :key="photoAt(memory.id)?.id" class="memory-slide">
                  <img :src="photoAt(memory.id)?.url" :alt="photoAt(memory.id)?.title || memory.imageHint" loading="lazy" />
                  <figcaption v-if="photoAt(memory.id)?.title || photoAt(memory.id)?.note">
                    <b v-if="photoAt(memory.id)?.title">{{ photoAt(memory.id)?.title }}</b>
                    <span v-if="photoAt(memory.id)?.note">{{ photoAt(memory.id)?.note }}</span>
                  </figcaption>
                </figure>
              </Transition>
              <template v-if="photosByMoment[memory.id].length > 1">
                <button class="carousel-arrow carousel-prev" :aria-label="`Previous photo for ${memory.title}`" @click="movePhoto(memory.id, -1)">‹</button>
                <button class="carousel-arrow carousel-next" :aria-label="`Next photo for ${memory.title}`" @click="movePhoto(memory.id, 1)">›</button>
                <span class="carousel-count">{{ (galleryIndexes[memory.id] || 0) + 1 }} / {{ photosByMoment[memory.id].length }}</span>
              </template>
            </div>
            <div v-else class="memory-placeholder" aria-hidden="true">
              <svg class="placeholder-art" viewBox="0 0 420 190" aria-hidden="true">
                <defs>
                  <linearGradient :id="`paper-${memory.id}`" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#fffaf2" /><stop offset="1" stop-color="#f2dfe6" /></linearGradient>
                </defs>
                <rect x="2" y="2" width="416" height="186" rx="24" :fill="`url(#paper-${memory.id})`" />
                <path d="M44 134c19-13 36-19 54-18m278 18c-19-13-36-19-54-18" fill="none" stroke="#b7c3a9" stroke-width="3" stroke-linecap="round" />
                <path d="M79 124c-8-13-20-13-23-3 8 8 16 9 23 3m13-7c1-14 12-20 19-12-3 10-10 14-19 12m210 0c-1-14-12-20-19-12 3 10 10 14 19 12m-13 7c8-13 20-13 23-3-8 8-16 9-23 3" fill="#d9b9b0" />
                <path d="M178 122c-10-9-9-25 2-29 8-3 15 3 20 10 5-7 12-13 20-10 11 4 12 20 2 29l-22 20z" fill="#dc9eac" opacity=".9" />
                <path d="M205 67c-6-6-5-15 2-18 5-2 9 2 12 7 3-5 7-9 12-7 7 3 8 12 2 18l-14 13z" fill="#f0c5c9" />
                <path d="m125 68 3 8 8 3-8 3-3 8-3-8-8-3 8-3zm169 37 2 6 6 2-6 2-2 6-2-6-6-2 6-2z" fill="#c89a57" />
                <circle cx="152" cy="45" r="3" fill="#c4869a" /><circle cx="275" cy="57" r="3" fill="#c4869a" />
                <path d="m161 143 3 3m91-69 3 3m-133 28 3 3m145 40 3 3" stroke="#fffaf5" stroke-width="4" stroke-linecap="round" />
              </svg>
            </div>
            <div class="memory-copy">
              <time :datetime="memory.date">{{ memory.dateLabel }}</time>
              <h3>{{ memory.title }}</h3>
              <p>{{ memory.description }}</p>
            </div>
          </article>
        </li>
      </ol>

      <article v-if="extraPhotos.length" class="extra-moments">
        <h3>More Little Moments</h3>
        <div class="memory-gallery">
          <figure v-for="photo in extraPhotos" :key="photo.id">
            <img :src="photo.url" :alt="photo.title || 'A favorite memory'" loading="lazy" />
            <figcaption>{{ photo.title || photo.note }}</figcaption>
          </figure>
        </div>
      </article>
    </section>

    <section class="recap-stats" aria-labelledby="stats-title">
      <div class="section-heading">
        <span class="recap-eyebrow">A few things about us</span>
        <h2 id="stats-title">Our First Month, in Little Numbers</h2>
      </div>
      <div class="stats-grid">
        <article v-for="stat in stats" :key="stat.label" class="stat-card">
          <span class="stat-value">{{ stat.value }}</span>
          <span class="stat-label">{{ stat.label }}</span>
        </article>
      </div>
    </section>

    <footer class="recap-closing">
      <span class="closing-heart" aria-hidden="true">♡</span>
      <h2>{{ firstMonth.closingTitle }}</h2>
      <p>{{ firstMonth.closingText }}</p>
      <span class="closing-signoff">With all my love</span>
    </footer>

    <section v-if="isOwner" class="recap-manager">
      <details>
        <summary>Add or remove recap photos</summary>
        <form class="recap-form" @submit.prevent="addPhoto">
          <label class="field">Choose a photo<input id="recap-photo-input" type="file" accept="image/*" required @change="pickPhoto" /></label>
          <label class="field">Story section
            <select v-model="draft.moment_id" @change="selectMoment">
              <option v-for="memory in firstMonth.memories" :key="memory.id" :value="memory.id">{{ memory.dateLabel }} · {{ memory.title }}</option>
            </select>
          </label>
          <label class="field">Photo caption<input v-model="draft.title" maxlength="80" placeholder="A little moment at Schönbrunn" /></label>
          <label class="field">A note (optional)<textarea v-model="draft.note" rows="3" maxlength="1000" placeholder="Something you want to remember about this photo…" /></label>
          <button class="btn" type="submit" :disabled="saving || !draft.file">{{ saving ? "Saving…" : "Add photo to this section" }}</button>
        </form>
        <p v-if="error" class="error recap-error">{{ error }}</p>
        <ul v-if="recapEntries.length" class="recap-photo-list">
          <li v-for="photo in recapEntries" :key="photo.id">
            <img :src="photo.url" :alt="photo.title || 'Recap photo'" />
            <span>{{ photo.title || firstMonth.memories.find((item) => item.id === photo.moment_id)?.title || 'Photo' }}</span>
            <button class="link" type="button" :disabled="deleting === photo.id" @click="deletePhoto(photo)">{{ deleting === photo.id ? "Deleting…" : "Delete" }}</button>
          </li>
        </ul>
      </details>
    </section>
  </main>
</template>
