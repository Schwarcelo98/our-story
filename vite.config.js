import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

// GitHub Pages serves a project site under /<repo-name>/, set by the deploy workflow.
export default defineConfig({ base: process.env.VITE_BASE || "/", plugins: [vue()] });
