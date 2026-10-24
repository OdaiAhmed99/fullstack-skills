import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Behind nginx: the browser talks to :80, so HMR's websocket goes through nginx too.
export default defineConfig({
  plugins: [react()],
  server: { host: true, port: 5173, hmr: { clientPort: 80 } },
});
