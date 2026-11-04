import { ref } from "vue";
import { supabase } from "./supabase";

const BUCKET = "photos";
export const entries = ref([]);

export async function loadAlbum() {
  const { data, error } = await supabase.from("memories").select("*").order("date", { ascending: false }).order("created_at", { ascending: false });
  if (error) throw error;
  const paths = data.map((entry) => entry.photo_path).filter(Boolean);
  const urls = {};
  if (paths.length) {
    const { data: signed, error: signError } = await supabase.storage.from(BUCKET).createSignedUrls(paths, 6 * 3600);
    if (signError) throw signError;
    for (const item of signed) if (item.path) urls[item.path] = item.signedUrl;
  }
  entries.value = data.map((entry) => ({ ...entry, url: urls[entry.photo_path] || null }));
}

export async function saveEntry({ id, title, date, note, photo, photoPath }) {
  const storage = supabase.storage.from(BUCKET);
  let path = photoPath || null;
  if (photo) {
    path = `${crypto.randomUUID()}.jpg`;
    const { error } = await storage.upload(path, photo, { contentType: "image/jpeg" });
    if (error) throw error;
  }
  const row = { title, date, note, photo_path: path };
  const result = id
    ? await supabase.from("memories").update(row).eq("id", id)
    : await supabase.from("memories").insert(row);
  if (result.error) {
    if (photo && path) await storage.remove([path]);
    throw result.error;
  }
  if (photo && photoPath) await storage.remove([photoPath]);
  await loadAlbum();
}

export async function removeEntry({ id, photoPath }) {
  const { error } = await supabase.from("memories").delete().eq("id", id);
  if (error) throw error;
  if (photoPath) {
    const { error: removeError } = await supabase.storage.from(BUCKET).remove([photoPath]);
    if (removeError) throw removeError;
  }
  await loadAlbum();
}

export async function resizeImage(file, max = 1600) {
  const bitmap = await createImageBitmap(file, { imageOrientation: "from-image" });
  const scale = Math.min(1, max / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement("canvas");
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext("2d").drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close();
  return new Promise((resolve, reject) => canvas.toBlob((blob) => (blob ? resolve(blob) : reject(new Error("encode failed"))), "image/jpeg", 0.85));
}
