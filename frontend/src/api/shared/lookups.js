// Shared dropdown calls - every picker in every app answers the same envelope:
// {total_items, total_pages, current_page, next_page, previous_page, data}
import { api } from "./client";

export const fetchPicker = (path, { search, ids, page = 1, pageSize = 20 } = {}) =>
  api
    .get(path, { params: { search: search || undefined, ids: ids?.join(","), page, page_size: pageSize } })
    .then((r) => r.data);

export const fetchFormOptions = (path) => api.get(path).then((r) => r.data);
