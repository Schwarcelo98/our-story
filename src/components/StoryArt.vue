<script setup>
import couplePortrait from "../assets/vero-daniel-cute-cartoon-blue-eyes.png";
</script>

<template>
  <div class="story-art" role="img" aria-label="Comic-style portrait of Vero and Daniel">
    <svg viewBox="0 0 320 260" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <path class="art-orbit" d="M38 133C57 37 247 17 282 105c34 86-99 151-172 116C40 193 65 83 144 66c61-13 115 24 102 67-10 34-57 45-83 22" />
      <path class="art-orbit art-orbit-inner" d="M69 142c17-49 94-76 146-43 32 20 17 64-20 69-30 4-48-14-43-34" />
      <path class="art-heart" d="M251 50c-10-12-29-1-18 13l16 15 17-15c12-13-7-25-17-13h2z" />
      <path class="art-star" d="m63 54 4 11 11 4-11 4-4 11-4-11-11-4 11-4z" />
      <path class="art-star art-star-two" d="m271 176 3 8 8 3-8 3-3 8-3-8-8-3 8-3z" />
      <circle class="art-dot" cx="67" cy="201" r="4" />
      <circle class="art-dot art-dot-two" cx="221" cy="35" r="3" />
    </svg>
    <img class="story-couple" :src="couplePortrait" alt="">
  </div>
</template>
