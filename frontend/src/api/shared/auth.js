// Login with username OR email + password (JWT). Used by every app - lives in shared.
import { api } from "./client";

export async function login(loginValue, password) {
  const { data } = await api.post("/auth/login/", { login: loginValue, password });
  localStorage.setItem("access", data.access);
  localStorage.setItem("refresh", data.refresh);
  return data.user;
}

export const getMe = () => api.get("/auth/me/").then((r) => r.data);

export function logout() {
  localStorage.removeItem("access");
  localStorage.removeItem("refresh");
}
