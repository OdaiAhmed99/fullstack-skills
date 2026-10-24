// The one HTTP client. Never import axios anywhere else - area files in src/api/<app>/ use `api`.
import axios from "axios";

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "/api",
  withCredentials: true,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("access");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Refresh once on 401, then retry the original request.
api.interceptors.response.use(
  (r) => r,
  async (error) => {
    const original = error.config;
    if (error.response?.status === 401 && !original._retry && localStorage.getItem("refresh")) {
      original._retry = true;
      const { data } = await axios.post(`${api.defaults.baseURL}/auth/refresh/`, {
        refresh: localStorage.getItem("refresh"),
      });
      localStorage.setItem("access", data.access);
      if (data.refresh) localStorage.setItem("refresh", data.refresh);
      return api(original);
    }
    return Promise.reject(error);
  }
);

