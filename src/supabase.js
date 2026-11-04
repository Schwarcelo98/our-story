import { createClient } from "@supabase/supabase-js";

const configuredUrl = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Accept either the project URL or its REST endpoint (older .env.local files used the latter).
const url = configuredUrl?.replace(/\/rest\/v1\/?$/, "").replace(/\/$/, "");

export const configured = Boolean(url && key);
export const supabase = configured ? createClient(url, key) : null;
