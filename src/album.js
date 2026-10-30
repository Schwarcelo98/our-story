import { ref } from "vue";
import { supabase } from "./supabase";

const BUCKET = "photos";

export const entries = ref([]);

export async function loadAlbum() {
  const { data, error } = await supabase
    .from("memories")
    .select("*")
    .order("date", { ascending: false })
    .order("created_at", { ascending: false });
  if (error) throw error;

  // The bucket is private, so photos are shown through short-lived signed URLs.
  const paths = data.map((e) => e.photo_path).filter(Boolean);
  const urls = {};
  if (paths.length) {
    const { data: signed, error: signError } = await supabase.storage.from(BUCKET).createSignedUrls(paths, 6 * 3600);
    if (signError) throw signError;
    for (const s of signed) urls[s.path] = s.signedUrl;
  }
  entries.value = data.map((e) => ({ ...e, url: urls[e.photo_path] || null }));
}

// `photo` is a new Blob to upload; `photoPath` is the existing file, kept if no new photo is given.
export async function saveEntry({ id, title, date, note, photo, photoPath }) {
  const storage = supabase.storage.from(BUCKET);
  let path = photoPath;
  if (photo) {
    path = `${crypto.randomUUID()}.jpg`;
    const { error } = await storage.upload(path, photo, { contentType: "image/jpeg" });
    if (error) throw error;
  }

  const row = { title, date, note, photo_path: path };
  const { error } = id
    ? await supabase.from("memories").update(row).eq("id", id)
    : await supabase.from("memories").insert(row);
  if (error) {
    if (photo) await storage.remove([path]);
    throw error;
  }
  if (photo && photoPath) await storage.remove([photoPath]);
  await loadAlbum();
}

export async function removeEntry({ id, photoPath }) {
  const { error } = await supabase.from("memories").delete().eq("id", id);
  if (error) throw error;
  if (photoPath) await supabase.storage.from(BUCKET).remove([photoPath]);
  await loadAlbum();
}

// Downscale and re-encode so a phone photo takes ~300 KB instead of several MB.
export async function resizeImage(file, max = 1600) {
  const bitmap = await createImageBitmap(file, { imageOrientation: "from-image" });
  const scale = Math.min(1, max / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement("canvas");
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext("2d").drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();
  return new Promise((resolve, reject) =>
    canvas.toBlob((b) => (b ? resolve(b) : reject(new Error("encode failed"))), "image/jpeg", 0.85)
  );
}
