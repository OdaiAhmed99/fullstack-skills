import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Local run (no Docker): Vite on :5173 forwards /api, /admin, /static, /media and /ws to Django on :8000.
// Docker: nginx on :80 does that routing, so the browser's HMR socket goes through port 80.
const backend = process.env.BACKEND_URL || "http://localhost:8000";
const inDocker = process.env.IN_DOCKER === "1";

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    hmr: inDocker ? { clientPort: 80 } : undefined,
    proxy: inDocker
      ? undefined
      : {
          "/api": backend,
          "/admin": backend,
          "/static": backend,
          "/media": backend,
          "/ws": { target: backend.replace("http", "ws"), ws: true },
        },
  },
});
