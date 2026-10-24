import React from "react";
import { createRoot } from "react-dom/client";
import "./styles/tokens.css";
import HealthPage from "./pages/core/HealthPage";

createRoot(document.getElementById("root")).render(<HealthPage />);
