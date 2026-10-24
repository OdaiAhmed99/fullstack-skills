// API calls of the `core` app only. One folder per backend app: src/api/<app>/index.js
import { api } from "../shared";

export const getHealth = () => api.get("/core/health/").then((r) => r.data);
