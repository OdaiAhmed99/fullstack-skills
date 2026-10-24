// The one dropdown for every growable list (shared-lookups). Responsive: full width on phones.
import { useEffect, useState } from "react";
import { fetchPicker } from "../../api/shared";
import "./Picker.css";

export default function Picker({ id, label, path, value, onChange, initialItems = [] }) {
  const [items, setItems] = useState(initialItems); // first page from form-options/
  const [search, setSearch] = useState("");

  useEffect(() => {
    if (!search) return;
    const t = setTimeout(() => fetchPicker(path, { search }).then((r) => setItems(r.data)), 300);
    return () => clearTimeout(t);
  }, [path, search]);

  return (
    <div className="picker">
      <label htmlFor={id}>{label}</label>
      <input
        id={`${id}-search`}
        type="search"
        placeholder="Search..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />
      <select id={id} value={value ?? ""} onChange={(e) => onChange(Number(e.target.value) || null)}>
        <option value="">-</option>
        {items.map((item) => (
          <option key={item.id} value={item.id}>{item.name}</option>
        ))}
      </select>
    </div>
  );
}
