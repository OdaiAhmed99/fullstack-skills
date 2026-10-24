// One error handler for every screen (frontend-integration skill, section 6).
export function handleApiError(error, { setFieldErrors, toast = console.warn, reload } = {}) {
  const status = error.response?.status;
  const data = error.response?.data || {};
  if (status === 400) {
    setFieldErrors?.(data); // field -> [messages]; non_field_errors shown on top
    return;
  }
  if (status === 403) toast("Not allowed.");
  else if (status === 404) toast("Not found.");
  else if (status === 409) toast("Someone already changed this. Reloading.");
  else toast("Something went wrong. Try again.");
  if (status === 403 || status === 409) reload?.();
}
