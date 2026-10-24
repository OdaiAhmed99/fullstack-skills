import { useEffect, useState } from "react";
import { getHealth } from "../../api/core";

export default function HealthPage() {
  const [status, setStatus] = useState("checking...");
  useEffect(() => {
    getHealth().then((d) => setStatus(d.status)).catch(() => setStatus("down"));
  }, []);
  return (
    <main className="page">
      <h1>Backend: {status}</h1>
    </main>
  );
}
