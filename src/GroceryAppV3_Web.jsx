import React, { useState, useEffect, useRef } from "react";
import ReactDOM from "react-dom/client";

// ─── 1. SCORING SYSTEM ────────────────────────────────────────────────────────

const NUTRI_BASE = { a: 90, b: 72, c: 54, d: 36, e: 18 };

// Risk levels: 0 = low, 1 = moderate, 2 = high, 3 = very high
const ADDITIVE_RISK = {
  // Preservatives
  E200: 0, E202: 0, E203: 0,
  E210: 2, E211: 2, E212: 2, E213: 2, E214: 2, E215: 2,
  E216: 3, E217: 3, E218: 1, E219: 1,
  E220: 1, E221: 1, E222: 1, E223: 1, E224: 1,
  E230: 2, E231: 2, E232: 2,
  E249: 3, E250: 3, E251: 3, E252: 3,
  // Antioxidants
  E300: 0, E301: 0, E302: 0, E304: 0,
  E306: 0, E307: 0, E308: 0, E309: 0,
  E310: 2, E311: 1, E312: 1, E319: 2, E320: 2, E321: 2,
  // Colorants
  E100: 0, E101: 0, E102: 2, E104: 1, E110: 2,
  E120: 1, E122: 2, E123: 3, E124: 2,
  E127: 1, E128: 2, E129: 2,
  E131: 2, E132: 0, E133: 1,
  E142: 2, E150a: 0, E150b: 0, E150c: 1, E150d: 1,
  E151: 2, E153: 1, E155: 2, E160a: 0, E160b: 0,
  E160c: 0, E160d: 0, E161b: 0,
  E162: 0, E163: 0, E170: 0, E171: 1, E172: 0,
  // Sweeteners
  E420: 0, E421: 0, E950: 1, E951: 2, E952: 2,
  E953: 0, E954: 2, E955: 1, E957: 0, E959: 1,
  E960: 0, E961: 1, E962: 1, E965: 0, E966: 0,
  E967: 0, E968: 0,
  // Emulsifiers
  E322: 0, E331: 0, E332: 0, E333: 0, E334: 0,
  E407: 1, E410: 0, E412: 0, E414: 0, E415: 0,
  E440: 0, E450: 0, E451: 0, E452: 0,
  E460: 0, E461: 0, E462: 0, E463: 0, E464: 0,
  E465: 0, E466: 0, E467: 0, E468: 0, E469: 0,
  E470a: 0, E470b: 0, E471: 0, E472a: 0, E472b: 0,
  E472c: 0, E472d: 0, E472e: 1, E472f: 0,
  E473: 0, E474: 0, E475: 0, E476: 1, E477: 0,
  E479b: 1, E481: 0, E482: 0, E483: 0, E491: 0,
  E492: 0, E493: 0, E494: 0, E495: 0,
  // Flavor enhancers
  E620: 1, E621: 2, E622: 1, E623: 1, E624: 1, E625: 1,
  E626: 1, E627: 1, E628: 1, E629: 1, E630: 1,
  E631: 1, E632: 1, E633: 1, E634: 1, E635: 1,
  // Thickeners
  E400: 0, E401: 0, E402: 0, E403: 0, E404: 0, E405: 0,
  E406: 0, E408: 1, E409: 0, E416: 1, E417: 0,
  E418: 0, E419: 0, E425: 1,
  // Modified starches
  E1404: 0, E1410: 0, E1412: 0, E1413: 0, E1414: 0,
  E1420: 0, E1422: 0, E1440: 0, E1442: 0, E1450: 0,
  E1451: 0, E1452: 0,
};

function parseAdditives(additivesArr) {
  if (!Array.isArray(additivesArr)) return [];
  return additivesArr
    .map(raw => {
      const code = raw.replace(/^en:/, "").toUpperCase().split(" ")[0];
      const risk = ADDITIVE_RISK[code] ?? null;
      return risk !== null ? { code, risk } : null;
    })
    .filter(Boolean);
}

function computeGistScore(grade, additives) {
  const base = NUTRI_BASE[grade?.toLowerCase()] ?? null;
  if (base === null) return null;
  const penalty = (additives || []).reduce((sum, a) => sum + a.risk * 3, 0);
  return Math.max(0, Math.min(100, Math.round(base - penalty)));
}

function nutriLabel(grade) {
  const g = grade?.toLowerCase();
  if (g === "a") return "Excellent";
  if (g === "b") return "Good";
  if (g === "c") return "Fair";
  if (g === "d") return "Poor";
  if (g === "e") return "Bad";
  return "Unknown";
}

function nutriColor(grade) {
  const g = grade?.toLowerCase();
  if (g === "a") return "#1a9e3f";
  if (g === "b") return "#7ac94b";
  if (g === "c") return "#f5c518";
  if (g === "d") return "#f5841f";
  if (g === "e") return "#e63c2f";
  return "#aaa";
}

function gistScoreColor(score) {
  if (score === null || score === undefined) return "#aaa";
  if (score >= 80) return "#1a9e3f";
  if (score >= 60) return "#7ac94b";
  if (score >= 40) return "#f5c518";
  if (score >= 20) return "#f5841f";
  return "#e63c2f";
}

// ─── 2. SHARED UI ATOMS ───────────────────────────────────────────────────────

function HealthBadge({ grade }) {
  const color = nutriColor(grade);
  const label = nutriLabel(grade);
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 4,
      background: color, color: "#fff", borderRadius: 8,
      padding: "2px 8px", fontSize: 11, fontWeight: 700,
      letterSpacing: 0.5, textTransform: "uppercase",
    }}>
      {grade ? grade.toUpperCase() : "?"} · {label}
    </span>
  );
}

function GistScoreBadge({ score }) {
  const color = gistScoreColor(score);
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 4,
      border: `2px solid ${color}`, color, borderRadius: 8,
      padding: "2px 8px", fontSize: 11, fontWeight: 700,
    }}>
      Gist {score !== null && score !== undefined ? score : "—"}
    </span>
  );
}

function AdditivesWarning({ additives }) {
  if (!additives || additives.length === 0) return null;
  const highRisk = additives.filter(a => a.risk >= 2);
  if (highRisk.length === 0) return null;
  return (
    <div style={{
      background: "#fff3cd", border: "1px solid #ffc107",
      borderRadius: 8, padding: "6px 10px", fontSize: 11,
      color: "#856404", marginTop: 6,
    }}>
      ⚠️ High-risk additives: {highRisk.map(a => a.code).join(", ")}
    </div>
  );
}

function RingScore({ score, size = 48 }) {
  const radius = (size - 6) / 2;
  const circumference = 2 * Math.PI * radius;
  const pct = score !== null && score !== undefined ? score / 100 : 0;
  const dash = pct * circumference;
  const color = gistScoreColor(score);
  return (
    <svg width={size} height={size} style={{ display: "block", flexShrink: 0 }}>
      <circle cx={size / 2} cy={size / 2} r={radius} fill="none" stroke="#eee" strokeWidth={5} />
      <circle
        cx={size / 2} cy={size / 2} r={radius}
        fill="none" stroke={color} strokeWidth={5}
        strokeDasharray={`${dash} ${circumference - dash}`}
        strokeDashoffset={circumference / 4}
        strokeLinecap="round"
      />
      <text
        x={size / 2} y={size / 2 + 4}
        textAnchor="middle" fontSize={size * 0.22}
        fontWeight={700} fill={color}
      >
        {score !== null && score !== undefined ? score : "—"}
      </text>
    </svg>
  );
}

// ─── 3. STORAGE HELPERS ───────────────────────────────────────────────────────

const STORAGE_KEY = "gist_grocery_v1";

function loadData() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch { return {}; }
}

function saveData(data) {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(data)); } catch {}
}

// ─── 4. DEFAULT CATEGORIES ────────────────────────────────────────────────────

const DEFAULT_CATEGORIES = [
  "Produce",
  "Dairy & Eggs",
  "Meat & Seafood",
  "Bakery",
  "Frozen",
  "Beverages",
  "Snacks",
  "Pantry",
  "Household",
  "Personal Care",
];

// ─── 5. STATIC PAGES ──────────────────────────────────────────────────────────

function PageShell({ title, onBack, children }) {
  return (
    <div style={{ minHeight: "100vh", background: "#f5f2ec", fontFamily: "'Lora', Georgia, serif" }}>
      <div style={{
        background: "#2a2118", color: "#fff",
        padding: "0 16px",
        position: "sticky", top: 0, zIndex: 10,
      }}>
        <div style={{
          display: "flex", alignItems: "center", gap: 12,
          padding: "14px 0",
        }}>
          <button
            onClick={onBack}
            style={{
              background: "none", border: "none", color: "#fff",
              fontSize: 22, cursor: "pointer", padding: "0 4px",
            }}
          >←</button>
          <h1 style={{ margin: 0, fontSize: 18, fontWeight: 700 }}>{title}</h1>
        </div>
      </div>
      <div style={{ padding: "20px 16px", maxWidth: 680, margin: "0 auto" }}>
        {children}
      </div>
    </div>
  );
}

function Section({ title, children }) {
  return (
    <div style={{ marginBottom: 28 }}>
      {title && (
        <h2 style={{ fontSize: 16, fontWeight: 700, marginBottom: 10, color: "#2a2118" }}>{title}</h2>
      )}
      <div style={{ fontSize: 14, lineHeight: 1.75, color: "#444" }}>{children}</div>
    </div>
  );
}

function PrivacyPage({ onBack }) {
  return (
    <PageShell title="Privacy Policy" onBack={onBack}>
      <Section title="Overview">
        Gist does not collect, store, or transmit any personal data. All your grocery lists and
        preferences are stored locally on your device using browser localStorage.
      </Section>
      <Section title="Data Storage">
        Your grocery lists are saved to localStorage under the key <code>gist_grocery_v1</code>.
        This data never leaves your device. Clearing your browser data will delete your lists.
      </Section>
      <Section title="Third-Party APIs">
        When you search for products or scan barcodes, product data is fetched from the Open Food
        Facts API (openfoodfacts.org). Open Food Facts is a non-profit, open-data project. No
        personal identifiers are sent in these requests.
      </Section>
      <Section title="Camera Access">
        The barcode scanner requests camera access via the browser's getUserMedia API. Camera data
        is processed locally and is never uploaded or stored.
      </Section>
      <Section title="Analytics">
        Gist does not use any analytics, tracking scripts, or advertising technologies.
      </Section>
      <Section title="Changes">
        This privacy policy may be updated from time to time. Continued use of the app implies
        acceptance of the current policy.
      </Section>
      <Section title="Contact">
        If you have privacy-related questions, please use the contact form in the About section.
      </Section>
    </PageShell>
  );
}

function TermsPage({ onBack }) {
  return (
    <PageShell title="Terms of Use" onBack={onBack}>
      <Section title="Acceptance">
        By using Gist, you agree to these terms. If you do not agree, please do not use the app.
      </Section>
      <Section title="Description">
        Gist is a free grocery list and product health scoring tool. It is provided "as is"
        without any warranties.
      </Section>
      <Section title="Product Data">
        Product information (nutrition scores, ingredients, additives) is sourced from Open Food
        Facts and may be inaccurate or incomplete. Do not rely solely on Gist for medical or
        dietary decisions.
      </Section>
      <Section title="Gist Score">
        The Gist Score is a proprietary composite metric for informational purposes only. It is
        not a medical or nutritional recommendation.
      </Section>
      <Section title="Limitation of Liability">
        Gist and its developers are not liable for any damages arising from your use of this app
        or the accuracy of product data.
      </Section>
      <Section title="Intellectual Property">
        The Gist app and scoring system are proprietary. Product data is provided by Open Food
        Facts under the Open Database License (ODbL).
      </Section>
      <Section title="Changes">
        These terms may be updated at any time. Continued use of the app constitutes acceptance.
      </Section>
    </PageShell>
  );
}

function FaqItem({ q, a }) {
  const [open, setOpen] = useState(false);
  return (
    <div style={{
      background: "#fff", borderRadius: 12, marginBottom: 8,
      boxShadow: "0 1px 6px rgba(0,0,0,0.06)", overflow: "hidden",
    }}>
      <button
        onClick={() => setOpen(o => !o)}
        style={{
          width: "100%", textAlign: "left", background: "none", border: "none",
          padding: "14px 16px", cursor: "pointer",
          display: "flex", justifyContent: "space-between", alignItems: "center",
          fontFamily: "'Lora', Georgia, serif", fontSize: 14, fontWeight: 600,
          color: "#2a2118",
        }}
      >
        {q}
        <span style={{ fontSize: 18, color: "#7ac94b", marginLeft: 8, flexShrink: 0 }}>
          {open ? "−" : "+"}
        </span>
      </button>
      {open && (
        <div style={{ padding: "0 16px 14px", fontSize: 14, color: "#555", lineHeight: 1.7 }}>
          {a}
        </div>
      )}
    </div>
  );
}

function ContactForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [msg, setMsg] = useState("");
  const [sent, setSent] = useState(false);

  function handleSubmit(e) {
    e.preventDefault();
    setSent(true);
  }

  if (sent) {
    return (
      <div style={{
        background: "#e6f4ea", border: "1px solid #7ac94b",
        borderRadius: 12, padding: "16px 20px", textAlign: "center",
        color: "#1a9e3f", fontSize: 15,
      }}>
        ✓ Message sent! We'll get back to you soon.
      </div>
    );
  }

  const inputStyle = {
    width: "100%", boxSizing: "border-box",
    border: "1px solid #ddd", borderRadius: 8,
    padding: "10px 12px", fontSize: 14,
    fontFamily: "'Lora', Georgia, serif",
    background: "#fff", marginBottom: 10, outline: "none",
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        placeholder="Your name"
        value={name} onChange={e => setName(e.target.value)}
        required style={inputStyle}
      />
      <input
        type="email" placeholder="Email address"
        value={email} onChange={e => setEmail(e.target.value)}
        required style={inputStyle}
      />
      <textarea
        placeholder="Your message..."
        value={msg} onChange={e => setMsg(e.target.value)}
        required rows={4}
        style={{ ...inputStyle, resize: "vertical" }}
      />
      <button
        type="submit"
        style={{
          background: "#7ac94b", color: "#fff", border: "none",
          borderRadius: 8, padding: "10px 24px", fontSize: 14,
          fontWeight: 700, cursor: "pointer",
        }}
      >
        Send Message
      </button>
    </form>
  );
}

function HelpPage({ onBack }) {
  const faqs = [
    {
      q: "How do I add items to my grocery list?",
      a: "Type in the search bar at the top of the Grocery List tab. Results from Open Food Facts will appear — tap any result to add it to a category.",
    },
    {
      q: "What is the Gist Score?",
      a: "The Gist Score (0–100) is a composite metric that starts with the Nutri-Score grade (A=90, B=72, C=54, D=36, E=18) and subtracts penalties for high-risk additives. Higher is better.",
    },
    {
      q: "What is Nutri-Score?",
      a: "Nutri-Score is a European nutrition label grading food from A (healthiest) to E (least healthy), based on nutrients like sugar, fat, fiber, and protein.",
    },
    {
      q: "What is NOVA group?",
      a: "NOVA classifies foods by processing level: 1 = unprocessed, 2 = processed culinary ingredients, 3 = processed foods, 4 = ultra-processed. Lower is better.",
    },
    {
      q: "How does the barcode scanner work?",
      a: "Tap the barcode icon and allow camera access. Point your camera at a product barcode. The app looks up the product in Open Food Facts.",
    },
    {
      q: "What is the Discover tab?",
      a: "Discover shows top-rated products in various categories, sourced from Open Food Facts. Toggle between grocery and order list view to add items.",
    },
    {
      q: "Is my data private?",
      a: "Yes. All list data is stored locally in your browser's localStorage. No personal data is ever sent to any server.",
    },
    {
      q: "How do I create a custom category?",
      a: "At the bottom of the Grocery List, tap '+ Add Category' and enter a name. The same option is available in the Order List tab.",
    },
  ];

  return (
    <PageShell title="Help" onBack={onBack}>
      <Section title="Frequently Asked Questions">
        {faqs.map((f, i) => <FaqItem key={i} q={f.q} a={f.a} />)}
      </Section>
    </PageShell>
  );
}

function AboutPage({ onBack }) {
  return (
    <PageShell title="About Gist" onBack={onBack}>
      <Section>
        <div style={{ textAlign: "center", marginBottom: 24 }}>
          <div style={{
            width: 72, height: 72, borderRadius: "50%",
            background: "linear-gradient(135deg, #7ac94b, #2a2118)",
            margin: "0 auto 12px", display: "flex",
            alignItems: "center", justifyContent: "center",
            fontSize: 32,
          }}>🥦</div>
          <div style={{ fontSize: 22, fontWeight: 700, color: "#2a2118" }}>Gist</div>
          <div style={{ fontSize: 13, color: "#888", marginTop: 4 }}>
            Grocery Intelligence, Simplified
          </div>
        </div>
      </Section>
      <Section title="What is Gist?">
        Gist helps you make healthier grocery choices. Search products, scan barcodes, and
        instantly see Nutri-Score grades, NOVA groups, additive warnings, and our proprietary
        Gist Score.
      </Section>
      <Section title="Product Data">
        All product data is sourced from <strong>Open Food Facts</strong> — a free, open,
        collaborative database of food products from around the world. We're grateful for
        their work.
      </Section>
      <Section title="The Gist Score">
        The Gist Score combines Nutri-Score with additive risk analysis to produce a single
        0–100 health indicator. It's a starting point for healthier choices, not a medical
        recommendation.
      </Section>
      <Section title="Contact Us">
        <ContactForm />
      </Section>
    </PageShell>
  );
}

// ─── 6. BARCODE SCANNER ───────────────────────────────────────────────────────

function BarcodeScanner({ onDetected, onClose }) {
  const videoRef = useRef(null);
  const streamRef = useRef(null);
  const [error, setError] = useState(null);
  const [hasCamera, setHasCamera] = useState(false);
  const [manual, setManual] = useState("");

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: "environment" },
        });
        if (!active) { stream.getTracks().forEach(t => t.stop()); return; }
        streamRef.current = stream;
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          videoRef.current.play();
          setHasCamera(true);
        }
      } catch {
        setError("Camera access denied or unavailable.");
      }
    })();
    return () => {
      active = false;
      if (streamRef.current) streamRef.current.getTracks().forEach(t => t.stop());
    };
  }, []);

  function handleManual(e) {
    e.preventDefault();
    if (manual.trim()) onDetected(manual.trim());
  }

  return (
    <div style={{
      position: "fixed", inset: 0, background: "rgba(0,0,0,0.85)",
      zIndex: 100, display: "flex", flexDirection: "column",
      alignItems: "center", justifyContent: "center",
    }}>
      <div style={{
        background: "#1a1a1a", borderRadius: 20, overflow: "hidden",
        width: "min(400px, 92vw)", padding: 20,
      }}>
        <div style={{
          display: "flex", justifyContent: "space-between",
          alignItems: "center", marginBottom: 16,
        }}>
          <h3 style={{ margin: 0, color: "#fff", fontSize: 16 }}>Scan Barcode</h3>
          <button
            onClick={onClose}
            style={{
              background: "rgba(255,255,255,0.1)", border: "none",
              color: "#fff", borderRadius: "50%", width: 32, height: 32,
              cursor: "pointer", fontSize: 18, display: "flex",
              alignItems: "center", justifyContent: "center",
            }}
          >×</button>
        </div>
        {error ? (
          <div style={{ color: "#f87171", textAlign: "center", padding: "20px 0", fontSize: 14 }}>
            {error}
          </div>
        ) : (
          <div style={{ position: "relative", borderRadius: 12, overflow: "hidden", background: "#000" }}>
            <video
              ref={videoRef}
              style={{ width: "100%", display: "block", maxHeight: 260, objectFit: "cover" }}
              playsInline muted
            />
            {hasCamera && (
              <div style={{
                position: "absolute", inset: 0, display: "flex",
                alignItems: "center", justifyContent: "center", pointerEvents: "none",
              }}>
                <div style={{
                  width: "70%", height: 2, background: "#7ac94b",
                  boxShadow: "0 0 8px #7ac94b",
                }} />
              </div>
            )}
          </div>
        )}
        <div style={{ marginTop: 16 }}>
          <p style={{ color: "#aaa", fontSize: 12, textAlign: "center", margin: "0 0 10px" }}>
            Or enter barcode manually:
          </p>
          <form onSubmit={handleManual} style={{ display: "flex", gap: 8 }}>
            <input
              value={manual} onChange={e => setManual(e.target.value)}
              placeholder="e.g. 3017620422003"
              style={{
                flex: 1, background: "#2a2a2a", border: "1px solid #444",
                borderRadius: 8, padding: "8px 12px", color: "#fff",
                fontSize: 14, outline: "none",
              }}
            />
            <button
              type="submit"
              style={{
                background: "#7ac94b", border: "none", borderRadius: 8,
                padding: "8px 14px", color: "#fff", fontWeight: 700,
                cursor: "pointer", fontSize: 14,
              }}
            >Go</button>
          </form>
        </div>
      </div>
    </div>
  );
}

// ─── 7. SCANNED PRODUCT MODAL ─────────────────────────────────────────────────

function ScannedProductModal({ product, loading, error, categories, onAdd, onClose }) {
  const [selectedCat, setSelectedCat] = useState(categories[0] || "");

  useEffect(() => {
    setSelectedCat(categories[0] || "");
  }, [categories]);

  return (
    <div style={{
      position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)",
      zIndex: 90, display: "flex", alignItems: "flex-end", justifyContent: "center",
    }}>
      <div style={{
        background: "#fff", borderRadius: "20px 20px 0 0",
        width: "min(500px, 100vw)", padding: "24px 20px 32px",
        maxHeight: "80vh", overflowY: "auto",
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 16 }}>
          <h3 style={{ margin: 0, fontSize: 17, color: "#2a2118" }}>Scanned Product</h3>
          <button
            onClick={onClose}
            style={{ background: "none", border: "none", fontSize: 22, cursor: "pointer", color: "#888" }}
          >×</button>
        </div>
        {loading && (
          <div style={{ textAlign: "center", padding: "30px 0", color: "#888" }}>
            Looking up product…
          </div>
        )}
        {!loading && error && (
          <div style={{ color: "#e63c2f", textAlign: "center", padding: "20px 0", fontSize: 14 }}>
            Product not found for barcode: <strong>{error}</strong>
            <p style={{ color: "#888", fontSize: 12, marginTop: 8 }}>
              This product may not be in the Open Food Facts database yet.
            </p>
          </div>
        )}
        {!loading && product && (
          <>
            <div style={{ display: "flex", gap: 14, marginBottom: 16 }}>
              {product.image_url && (
                <img
                  src={product.image_url} alt={product.name}
                  style={{
                    width: 72, height: 72, objectFit: "contain",
                    borderRadius: 10, border: "1px solid #eee", flexShrink: 0,
                  }}
                />
              )}
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 700, fontSize: 15, color: "#2a2118", marginBottom: 4 }}>
                  {product.name}
                </div>
                <div style={{ fontSize: 12, color: "#888", marginBottom: 8 }}>{product.brand}</div>
                <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                  <HealthBadge grade={product.nutriscore_grade} />
                  <GistScoreBadge score={product.gistScore} />
                </div>
              </div>
            </div>
            <AdditivesWarning additives={product.additives} />
            <div style={{ marginTop: 16 }}>
              <label style={{ fontSize: 13, color: "#666", display: "block", marginBottom: 6 }}>
                Add to category:
              </label>
              <select
                value={selectedCat}
                onChange={e => setSelectedCat(e.target.value)}
                style={{
                  width: "100%", padding: "8px 12px", borderRadius: 8,
                  border: "1px solid #ddd", fontSize: 14,
                  fontFamily: "'Lora', Georgia, serif", marginBottom: 12,
                }}
              >
                {categories.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
              <button
                onClick={() => onAdd(product, selectedCat)}
                style={{
                  width: "100%", background: "#7ac94b", color: "#fff",
                  border: "none", borderRadius: 10, padding: "12px",
                  fontSize: 15, fontWeight: 700, cursor: "pointer",
                }}
              >
                Add to List
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

// ─── 8. SEARCH RESULT ROW ─────────────────────────────────────────────────────

function SearchResultRow({ item, categories, onAdd }) {
  const [selectedCat, setSelectedCat] = useState(categories[0] || "");
  const [hovered, setHovered] = useState(false);

  useEffect(() => {
    setSelectedCat(categories[0] || "");
  }, [categories]);

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: hovered ? "#f9f7f3" : "#fff",
        borderBottom: "1px solid #f0ece4",
        padding: "10px 14px",
        transition: "background 0.15s",
      }}
    >
      <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
        {item.image_url && (
          <img
            src={item.image_url} alt={item.name}
            style={{ width: 44, height: 44, objectFit: "contain", borderRadius: 6, flexShrink: 0 }}
          />
        )}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontWeight: 600, fontSize: 13, color: "#2a2118",
            whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
          }}>
            {item.name}
          </div>
          <div style={{ fontSize: 11, color: "#888", marginBottom: 4 }}>{item.brand}</div>
          <div style={{ display: "flex", gap: 5, flexWrap: "wrap" }}>
            <HealthBadge grade={item.nutriscore_grade} />
            <GistScoreBadge score={item.gistScore} />
          </div>
        </div>
      </div>
      <div style={{ display: "flex", gap: 6, marginTop: 8, alignItems: "center" }}>
        <select
          value={selectedCat}
          onChange={e => setSelectedCat(e.target.value)}
          onClick={e => e.stopPropagation()}
          style={{
            flex: 1, padding: "6px 8px", borderRadius: 6,
            border: "1px solid #ddd", fontSize: 12,
            fontFamily: "'Lora', Georgia, serif",
          }}
        >
          {categories.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
        <button
          onClick={() => onAdd(item, selectedCat)}
          style={{
            background: "#7ac94b", color: "#fff", border: "none",
            borderRadius: 6, padding: "6px 12px", fontSize: 12,
            fontWeight: 700, cursor: "pointer", whiteSpace: "nowrap",
          }}
        >+ Add</button>
      </div>
    </div>
  );
}

// ─── 9. ORDER LIST STORAGE ────────────────────────────────────────────────────

const ORDER_STORAGE_KEY = "gist_orderlist_v1";

function loadOrderData() {
  try {
    const raw = localStorage.getItem(ORDER_STORAGE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch { return {}; }
}

function saveOrderData(data) {
  try { localStorage.setItem(ORDER_STORAGE_KEY, JSON.stringify(data)); } catch {}
}

// ─── 10. API FUNCTIONS ────────────────────────────────────────────────────────

const OFF_FIELDS = "product_name,brands,nutriscore_grade,nova_group,image_front_small_url,ingredients_text,additives_tags";

function mapProduct(p) {
  if (!p) return null;
  const name = p.product_name?.trim();
  const nutriscore_grade = p.nutriscore_grade?.trim()?.toLowerCase();
  if (!name || !nutriscore_grade || !/^[a-e]$/.test(nutriscore_grade)) return null;
  const additives = parseAdditives(p.additives_tags || []);
  return {
    name,
    brand: p.brands?.split(",")[0]?.trim() || "",
    nutriscore_grade,
    nova_group: p.nova_group ? Number(p.nova_group) : null,
    image_url: p.image_front_small_url || null,
    additives,
    gistScore: computeGistScore(nutriscore_grade, additives),
  };
}

async function fetchByBarcode(barcode) {
  try {
    const res = await fetch(`https://world.openfoodfacts.org/api/v0/product/${barcode}.json`);
    const data = await res.json();
    if (data.status !== 1) return null;
    return mapProduct(data.product);
  } catch { return null; }
}

async function fetchBySearch(query) {
  try {
    const url = new URL("https://world.openfoodfacts.org/cgi/search.pl");
    url.searchParams.set("search_terms", query);
    url.searchParams.set("search_simple", "1");
    url.searchParams.set("action", "process");
    url.searchParams.set("json", "1");
    url.searchParams.set("page_size", "12");
    url.searchParams.set("fields", OFF_FIELDS);
    const res = await fetch(url.toString());
    const data = await res.json();
    return (data.products || []).map(mapProduct).filter(Boolean).slice(0, 10);
  } catch { return []; }
}

// ─── 11. GROCERY ITEM ROW ─────────────────────────────────────────────────────

function GroceryItemRow({ item, onToggle, onRemove }) {
  const [hovered, setHovered] = useState(false);
  return (
    <div
      onMouseEnter={e => { e.currentTarget.style.background = "#f9f7f3"; setHovered(true); }}
      onMouseLeave={e => { e.currentTarget.style.background = "#fff"; setHovered(false); }}
      style={{
        display: "flex", alignItems: "center", gap: 10,
        padding: "10px 14px", borderBottom: "1px solid #f5f2ec",
        transition: "background 0.15s",
      }}
    >
      <input
        type="checkbox"
        checked={item.checked}
        onChange={onToggle}
        style={{ width: 18, height: 18, accentColor: "#7ac94b", cursor: "pointer", flexShrink: 0 }}
      />
      <span style={{
        flex: 1, fontSize: 14, color: item.checked ? "#bbb" : "#2a2118",
        textDecoration: item.checked ? "line-through" : "none",
        transition: "color 0.15s",
      }}>
        {item.name}
      </span>
      {item.nutri && (
        <span style={{
          background: nutriColor(item.nutri), color: "#fff",
          borderRadius: 4, padding: "1px 6px", fontSize: 10, fontWeight: 700, flexShrink: 0,
        }}>
          {item.nutri.toUpperCase()}
        </span>
      )}
      {hovered && (
        <button
          onClick={onRemove}
          style={{
            background: "none", border: "none", color: "#e63c2f",
            cursor: "pointer", fontSize: 16, padding: "0 2px", flexShrink: 0,
          }}
        >×</button>
      )}
    </div>
  );
}

// ─── TAB BAR ──────────────────────────────────────────────────────────────────

function TabBar({ currentTab, onTabChange }) {
  const tabs = [
    { id: "list",        label: "List",     icon: "📋" },
    { id: "order",       label: "Order",    icon: "🛒" },
    { id: "suggestions", label: "Discover", icon: "✨" },
  ];
  return (
    <div style={{
      position: "fixed", bottom: 0, left: 0, right: 0,
      background: "#fff", borderTop: "1px solid #eee",
      display: "flex",
      paddingBottom: "env(safe-area-inset-bottom, 0px)",
      zIndex: 30,
    }}>
      {tabs.map(t => (
        <button
          key={t.id}
          onClick={() => onTabChange(t.id)}
          style={{
            flex: 1, background: "none", border: "none",
            padding: "10px 0 8px", cursor: "pointer",
            display: "flex", flexDirection: "column",
            alignItems: "center", gap: 2,
          }}
        >
          <span style={{ fontSize: 20 }}>{t.icon}</span>
          <span style={{
            fontSize: 10, fontWeight: currentTab === t.id ? 700 : 400,
            color: currentTab === t.id ? "#7ac94b" : "#aaa",
            fontFamily: "'Lora', Georgia, serif",
          }}>
            {t.label}
          </span>
        </button>
      ))}
    </div>
  );
}

// ─── APP COMPONENT ────────────────────────────────────────────────────────────

function App() {
  // Grocery list state
  const [groceries, setGroceries] = useState(loadData);
  const [collapsed, setCollapsed] = useState({});
  const [addingCat, setAddingCat] = useState(false);
  const [newCat, setNewCat] = useState("");

  // Order list state
  const [orderList, setOrderList] = useState(loadOrderData);

  // Search state (Grocery List)
  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [searchError, setSearchError] = useState("");
  const debounceRef = useRef(null);

  // Scanner state
  const [scannerOpen, setScannerOpen] = useState(false);
  const [scannedProduct, setScannedProduct] = useState(null);
  const [scanLoading, setScanLoading] = useState(false);
  const [scanError, setScanError] = useState(null);

  // Navigation state
  const [page, setPage] = useState(null);   // null | 'help' | 'privacy' | 'terms' | 'about'
  const [tab, setTab] = useState("list");   // 'list' | 'order' | 'suggestions'

  // Persist state
  useEffect(() => { saveData(groceries); }, [groceries]);
  useEffect(() => { saveOrderData(orderList); }, [orderList]);

  // Seed default categories on first run
  useEffect(() => {
    setGroceries(prev => {
      if (Object.keys(prev).length > 0) return prev;
      const init = {};
      DEFAULT_CATEGORIES.forEach(c => { init[c] = []; });
      return init;
    });
  }, []);

  // Search debounce
  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (!query.trim()) { setResults([]); setSearchError(""); return; }
    setSearching(true);
    debounceRef.current = setTimeout(async () => {
      try {
        const res = await fetchBySearch(query.trim());
        setResults(res);
        setSearchError(res.length === 0 ? "No products found." : "");
      } catch {
        setSearchError("Search failed. Check your connection.");
      } finally { setSearching(false); }
    }, 500);
    return () => clearTimeout(debounceRef.current);
  }, [query]);

  // ── Grocery list handlers ──

  function addToGroceries(item, catName) {
    setGroceries(prev => {
      const cat = prev[catName] || [];
      if (cat.some(i => i.name === item.name)) return prev;
      return {
        ...prev,
        [catName]: [...cat, { name: item.name, checked: false, nutri: item.nutriscore_grade || null }],
      };
    });
    setQuery("");
    setResults([]);
  }

  function toggleGroceryItem(catName, idx) {
    setGroceries(prev => ({
      ...prev,
      [catName]: prev[catName].map((item, i) =>
        i === idx ? { ...item, checked: !item.checked } : item
      ),
    }));
  }

  function removeGroceryItem(catName, idx) {
    setGroceries(prev => ({
      ...prev,
      [catName]: prev[catName].filter((_, i) => i !== idx),
    }));
  }

  function clearCheckedGroceries() {
    setGroceries(prev => {
      const next = {};
      Object.entries(prev).forEach(([cat, items]) => { next[cat] = items.filter(i => !i.checked); });
      return next;
    });
  }

  function addGroceryCategory(name) {
    const trimmed = name.trim();
    if (!trimmed) return;
    setGroceries(prev => prev[trimmed] ? prev : { ...prev, [trimmed]: [] });
    setAddingCat(false);
    setNewCat("");
  }

  // ── Order list handlers ──

  function addToOrder(item, catName) {
    setOrderList(prev => {
      const cat = prev[catName] || [];
      const existing = cat.findIndex(i => i.name === item.name);
      if (existing !== -1) {
        return {
          ...prev,
          [catName]: cat.map((i, idx) =>
            idx === existing ? { ...i, qty: (i.qty || 1) + 1 } : i
          ),
        };
      }
      return {
        ...prev,
        [catName]: [...cat, { name: item.name, checked: false, nutri: item.nutriscore_grade || null, qty: 1 }],
      };
    });
  }

  function toggleOrderItem(catName, idx) {
    setOrderList(prev => ({
      ...prev,
      [catName]: prev[catName].map((item, i) =>
        i === idx ? { ...item, checked: !item.checked } : item
      ),
    }));
  }

  function removeOrderItem(catName, idx) {
    setOrderList(prev => ({
      ...prev,
      [catName]: prev[catName].filter((_, i) => i !== idx),
    }));
  }

  function updateOrderQty(catName, idx, qty) {
    if (qty < 1) { removeOrderItem(catName, idx); return; }
    setOrderList(prev => ({
      ...prev,
      [catName]: prev[catName].map((item, i) =>
        i === idx ? { ...item, qty } : item
      ),
    }));
  }

  function addOrderCategory(name) {
    const trimmed = name.trim();
    if (!trimmed) return;
    setOrderList(prev => prev[trimmed] ? prev : { ...prev, [trimmed]: [] });
  }

  function clearCheckedOrders() {
    setOrderList(prev => {
      const next = {};
      Object.entries(prev).forEach(([cat, items]) => { next[cat] = items.filter(i => !i.checked); });
      return next;
    });
  }

  // ── Scanner handlers ──

  async function handleBarcodeScan(barcode) {
    setScannerOpen(false);
    setScanLoading(true);
    setScanError(null);
    setScannedProduct(null);
    const product = await fetchByBarcode(barcode);
    setScanLoading(false);
    if (!product) setScanError(barcode);
    else setScannedProduct(product);
  }

  // Category name lists for pickers
  const groceryCatNames = Object.keys(groceries).length > 0
    ? Object.keys(groceries)
    : DEFAULT_CATEGORIES;

  const orderCatNames = Object.keys(orderList).length > 0
    ? Object.keys(orderList)
    : ["General"];

  // ── Static page routing ──
  if (page === "help")    return <HelpPage onBack={() => setPage(null)} />;
  if (page === "privacy") return <PrivacyPage onBack={() => setPage(null)} />;
  if (page === "terms")   return <TermsPage onBack={() => setPage(null)} />;
  if (page === "about")   return <AboutPage onBack={() => setPage(null)} />;

  // ── Tab routing ──
  if (tab === "suggestions") {
    return (
      <SuggestionsPage
        onAddToList={addToGroceries}
        onAddToOrder={addToOrder}
        categories={groceryCatNames}
        orderCategories={orderCatNames}
        onTabChange={setTab}
        currentTab={tab}
      />
    );
  }

  if (tab === "order") {
    return (
      <OrderListPage
        orderList={orderList}
        onAddToOrder={addToOrder}
        onToggle={toggleOrderItem}
        onRemove={removeOrderItem}
        onUpdateQty={updateOrderQty}
        onAddCategory={addOrderCategory}
        onClearChecked={clearCheckedOrders}
        onTabChange={setTab}
        currentTab={tab}
      />
    );
  }

  // ── Grocery List (default tab) ──
  const checkedCount = Object.values(groceries).flat().filter(i => i.checked).length;
  const showDropdown = query.trim().length > 0;

  return (
    <div style={{ minHeight: "100vh", background: "#f5f2ec", fontFamily: "'Lora', Georgia, serif", paddingBottom: 72 }}>
      {/* Header */}
      <div style={{
        background: "#2a2118", color: "#fff",
        padding: "0 16px",
        position: "sticky", top: 0, zIndex: 20,
      }}>
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "14px 0 10px",
        }}>
          <div style={{ fontWeight: 800, fontSize: 22, letterSpacing: -0.5 }}>🥦 Gist</div>
          <div style={{ display: "flex", gap: 8 }}>
            <button
              onClick={() => setScannerOpen(true)}
              style={{
                background: "rgba(255,255,255,0.1)", border: "none",
                color: "#fff", borderRadius: 8, padding: "6px 12px",
                cursor: "pointer", fontSize: 16,
              }}
            >📷</button>
            <button
              onClick={() => setPage("about")}
              style={{
                background: "rgba(255,255,255,0.1)", border: "none",
                color: "#fff", borderRadius: 8, padding: "6px 12px",
                cursor: "pointer", fontSize: 16,
              }}
            >ℹ️</button>
          </div>
        </div>
        {/* Search bar */}
        <div style={{ position: "relative", paddingBottom: 12 }}>
          <input
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Search products to add…"
            style={{
              width: "100%", boxSizing: "border-box",
              background: "rgba(255,255,255,0.12)",
              border: "1px solid rgba(255,255,255,0.2)",
              borderRadius: 10, padding: "10px 40px 10px 14px",
              color: "#fff", fontSize: 14, outline: "none",
              fontFamily: "'Lora', Georgia, serif",
            }}
          />
          {searching && (
            <div style={{
              position: "absolute", right: 12, top: "50%",
              transform: "translateY(-50%)",
              width: 16, height: 16, border: "2px solid #7ac94b",
              borderTopColor: "transparent", borderRadius: "50%",
              animation: "spin 0.6s linear infinite",
            }} />
          )}
        </div>
      </div>

      {/* Search dropdown */}
      {showDropdown && (
        <div style={{
          background: "#fff", boxShadow: "0 4px 20px rgba(0,0,0,0.12)",
          borderRadius: "0 0 12px 12px", overflow: "hidden",
          position: "sticky", top: 90, zIndex: 15,
        }}>
          {searchError && (
            <div style={{ padding: "14px 16px", color: "#888", fontSize: 13, textAlign: "center" }}>
              {searchError}
            </div>
          )}
          {results.map((item, i) => (
            <SearchResultRow
              key={i}
              item={item}
              categories={groceryCatNames}
              onAdd={addToGroceries}
            />
          ))}
        </div>
      )}

      {/* Grocery list */}
      <div style={{ padding: "16px 14px", maxWidth: 600, margin: "0 auto" }}>
        {checkedCount > 0 && (
          <button
            onClick={clearCheckedGroceries}
            style={{
              background: "#fff", border: "1px solid #ddd",
              borderRadius: 8, padding: "6px 14px",
              fontSize: 12, color: "#888", cursor: "pointer",
              marginBottom: 14, display: "block",
            }}
          >
            Clear {checkedCount} checked item{checkedCount !== 1 ? "s" : ""}
          </button>
        )}

        {Object.entries(groceries).map(([catName, items]) => (
          <div key={catName} style={{ marginBottom: 16 }}>
            <button
              onClick={() => setCollapsed(prev => ({ ...prev, [catName]: !prev[catName] }))}
              style={{
                width: "100%", background: "none", border: "none",
                textAlign: "left", cursor: "pointer",
                display: "flex", justifyContent: "space-between", alignItems: "center",
                padding: "6px 2px", marginBottom: 6,
              }}
            >
              <span style={{ fontWeight: 700, fontSize: 14, color: "#2a2118" }}>
                {catName}
                <span style={{ color: "#bbb", fontWeight: 400, marginLeft: 8, fontSize: 12 }}>
                  {items.length}
                </span>
              </span>
              <span style={{ color: "#bbb", fontSize: 12 }}>
                {collapsed[catName] ? "▶" : "▼"}
              </span>
            </button>
            {!collapsed[catName] && (
              <div style={{
                background: "#fff", borderRadius: 12,
                boxShadow: "0 1px 6px rgba(0,0,0,0.06)",
                overflow: "hidden",
              }}>
                {items.length === 0 ? (
                  <div style={{ padding: "12px 16px", color: "#ccc", fontSize: 13, textAlign: "center" }}>
                    No items yet
                  </div>
                ) : (
                  items.map((item, idx) => (
                    <GroceryItemRow
                      key={idx}
                      item={item}
                      onToggle={() => toggleGroceryItem(catName, idx)}
                      onRemove={() => removeGroceryItem(catName, idx)}
                    />
                  ))
                )}
              </div>
            )}
          </div>
        ))}

        {/* Add category */}
        {addingCat ? (
          <form
            onSubmit={e => { e.preventDefault(); addGroceryCategory(newCat); }}
            style={{ display: "flex", gap: 8, marginTop: 8 }}
          >
            <input
              autoFocus
              value={newCat}
              onChange={e => setNewCat(e.target.value)}
              placeholder="Category name"
              style={{
                flex: 1, border: "1px solid #ddd", borderRadius: 8,
                padding: "8px 12px", fontSize: 14,
                fontFamily: "'Lora', Georgia, serif", outline: "none",
              }}
            />
            <button
              type="submit"
              style={{
                background: "#7ac94b", color: "#fff", border: "none",
                borderRadius: 8, padding: "8px 14px", fontWeight: 700,
                cursor: "pointer", fontSize: 14,
              }}
            >Add</button>
            <button
              type="button"
              onClick={() => { setAddingCat(false); setNewCat(""); }}
              style={{
                background: "#eee", border: "none", borderRadius: 8,
                padding: "8px 10px", cursor: "pointer", fontSize: 14,
              }}
            >✕</button>
          </form>
        ) : (
          <button
            onClick={() => setAddingCat(true)}
            style={{
              width: "100%", background: "none",
              border: "2px dashed #ddd", borderRadius: 10,
              padding: "10px", color: "#bbb", fontSize: 13,
              cursor: "pointer", marginTop: 8,
            }}
          >
            + Add Category
          </button>
        )}

        {/* Footer links */}
        <div style={{
          marginTop: 32, paddingTop: 20,
          borderTop: "1px solid #e8e4de",
          display: "flex", justifyContent: "center", gap: 20,
        }}>
          {["help", "privacy", "terms", "about"].map(p => (
            <button
              key={p}
              onClick={() => setPage(p)}
              style={{
                background: "none", border: "none", color: "#bbb",
                cursor: "pointer", fontSize: 11,
                fontFamily: "'Lora', Georgia, serif",
                textTransform: "capitalize",
              }}
            >{p}</button>
          ))}
        </div>
      </div>

      <TabBar currentTab={tab} onTabChange={setTab} />

      {scannerOpen && (
        <BarcodeScanner
          onDetected={handleBarcodeScan}
          onClose={() => setScannerOpen(false)}
        />
      )}

      {(scannedProduct || scanLoading || scanError) && (
        <ScannedProductModal
          product={scannedProduct}
          loading={scanLoading}
          error={scanError}
          categories={groceryCatNames}
          onAdd={(item, cat) => { addToGroceries(item, cat); setScannedProduct(null); setScanError(null); }}
          onClose={() => { setScannedProduct(null); setScanError(null); }}
        />
      )}

      <style>{`
        @keyframes spin { to { transform: translateY(-50%) rotate(360deg); } }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes shimmer { to { background-position: -200% 0; } }
        ::-webkit-scrollbar { width: 0; height: 0; }
      `}</style>
    </div>
  );
}

// ─── 12. DISCOVER CATEGORIES ─────────────────────────────────────────────────

const GROCERY_CATS = [
  { id: "meat",       label: "Meat",       emoji: "🥩", tag: "en:meats",           g1: "#c0392b", g2: "#e74c3c", bg: "#fdf0ef" },
  { id: "desserts",   label: "Desserts",   emoji: "🍰", tag: "en:desserts",         g1: "#8e44ad", g2: "#e056d7", bg: "#f9eef9" },
  { id: "vegetables", label: "Vegetables", emoji: "🥦", tag: "en:vegetables",       g1: "#1a9e3f", g2: "#7ac94b", bg: "#eef9f1" },
  { id: "fruits",     label: "Fruits",     emoji: "🍎", tag: "en:fruits",           g1: "#e67e22", g2: "#f39c12", bg: "#fdf6ec" },
  { id: "drinks",     label: "Drinks",     emoji: "🥤", tag: "en:beverages",        g1: "#2980b9", g2: "#3498db", bg: "#eef5fb" },
  { id: "bread",      label: "Bread",      emoji: "🍞", tag: "en:breads",           g1: "#d35400", g2: "#e67e22", bg: "#fdf3ec" },
  { id: "dairy",      label: "Dairy",      emoji: "🧀", tag: "en:dairy-products",   g1: "#f39c12", g2: "#f1c40f", bg: "#fdfaec" },
  { id: "frozen",     label: "Frozen",     emoji: "❄️", tag: "en:frozen-foods",     g1: "#2471a3", g2: "#5dade2", bg: "#eef4fb" },
  { id: "dips",       label: "Dips",       emoji: "🫙", tag: "en:dips",             g1: "#7d6608", g2: "#d4ac0d", bg: "#fdfaee" },
  { id: "store",      label: "Store",      emoji: "🏪", tag: "en:groceries",        g1: "#2a2118", g2: "#7a6550", bg: "#f5f2ec" },
];

const ORDER_CATS = [
  { id: "snacks",      label: "Snacks",      emoji: "🍿", tag: "en:snacks",           g1: "#e67e22", g2: "#f39c12", bg: "#fdf6ec" },
  { id: "baking",      label: "Baking",      emoji: "🎂", tag: "en:baking",           g1: "#8e44ad", g2: "#9b59b6", bg: "#f4edf9" },
  { id: "sauces",      label: "Sauces",      emoji: "🍅", tag: "en:sauces",           g1: "#c0392b", g2: "#e74c3c", bg: "#fdf0ef" },
  { id: "canned",      label: "Canned",      emoji: "🥫", tag: "en:canned-foods",     g1: "#7d6608", g2: "#d4ac0d", bg: "#fdfaee" },
  { id: "seasonings",  label: "Seasonings",  emoji: "🧂", tag: "en:seasonings",       g1: "#2a2118", g2: "#7a6550", bg: "#f5f2ec" },
  { id: "hair",        label: "Hair",        emoji: "💇", tag: "en:hair-care",        g1: "#8e44ad", g2: "#e056d7", bg: "#f9eef9" },
  { id: "bodywash",    label: "Body Wash",   emoji: "🚿", tag: "en:body-washes",      g1: "#2980b9", g2: "#3498db", bg: "#eef5fb" },
  { id: "moisturizer", label: "Moisturizer", emoji: "🧴", tag: "en:moisturizers",     g1: "#1a9e3f", g2: "#7ac94b", bg: "#eef9f1" },
  { id: "other",       label: "Other",       emoji: "📦", tag: "en:groceries",        g1: "#7f8c8d", g2: "#95a5a6", bg: "#f5f5f5" },
  { id: "naturals",    label: "Naturals",    emoji: "🌿", tag: "en:organic-products", g1: "#1a9e3f", g2: "#2ecc71", bg: "#eef9f3" },
];

const SUGG_CATS = GROCERY_CATS;

// ─── 13. DISCOVER HELPERS + FETCH ─────────────────────────────────────────────

const SUGG_GRADE_COLORS = {
  a: "#1a9e3f", b: "#7ac94b", c: "#f5c518", d: "#f5841f", e: "#e63c2f",
};

const SUGG_GRADE_ORDER = ["a", "b", "c", "d", "e"];

const SUGG_RATINGS = {
  a: "Excellent", b: "Good", c: "Fair", d: "Poor", e: "Bad",
};

async function fetchSuggestions(tag) {
  try {
    const url = new URL("https://world.openfoodfacts.org/cgi/search.pl");
    url.searchParams.set("tagtype_0", "categories");
    url.searchParams.set("tag_contains_0", "contains");
    url.searchParams.set("tag_0", tag);
    url.searchParams.set("sort_by", "unique_scans_n");
    url.searchParams.set("action", "process");
    url.searchParams.set("json", "1");
    url.searchParams.set("page_size", "30");
    url.searchParams.set("fields", OFF_FIELDS);
    const res = await fetch(url.toString());
    const data = await res.json();
    const products = (data.products || [])
      .map(p => {
        const m = mapProduct(p);
        if (!m) return null;
        const ingredients = p.ingredients_text?.trim().substring(0, 140) || "";
        return { ...m, img: m.image_url, grade: m.nutriscore_grade, nova: m.nova_group, ingredients };
      })
      .filter(Boolean);
    products.sort((a, b) => {
      const ga = SUGG_GRADE_ORDER.indexOf(a.grade);
      const gb = SUGG_GRADE_ORDER.indexOf(b.grade);
      if (ga !== gb) return ga - gb;
      return (b.gistScore || 0) - (a.gistScore || 0);
    });
    return products.slice(0, 10);
  } catch { return []; }
}

// ─── 14. SUGG NUTRI ARC ───────────────────────────────────────────────────────

function SuggNutriArc({ grade, size = 44 }) {
  const radius = (size - 6) / 2;
  const circumference = 2 * Math.PI * radius;
  const gradeIdx = SUGG_GRADE_ORDER.indexOf(grade?.toLowerCase());
  const pct = gradeIdx >= 0 ? 1 - gradeIdx / 4 : 0;
  const dash = pct * circumference;
  const color = SUGG_GRADE_COLORS[grade?.toLowerCase()] || "#aaa";
  return (
    <svg width={size} height={size} style={{ display: "block", flexShrink: 0 }}>
      <circle cx={size / 2} cy={size / 2} r={radius} fill="none" stroke="#eee" strokeWidth={5} />
      <circle
        cx={size / 2} cy={size / 2} r={radius}
        fill="none" stroke={color} strokeWidth={5}
        strokeDasharray={`${dash} ${circumference - dash}`}
        strokeDashoffset={circumference / 4}
        strokeLinecap="round"
      />
      <text
        x={size / 2} y={size / 2 + 4}
        textAnchor="middle" fontSize={size * 0.28}
        fontWeight={700} fill={color}
      >
        {grade ? grade.toUpperCase() : "?"}
      </text>
    </svg>
  );
}

// ─── 15. SUGG SKELETON ────────────────────────────────────────────────────────

function SuggSkeleton() {
  const shimmer = {
    background: "linear-gradient(90deg, #f0ece4 25%, #e8e2d8 50%, #f0ece4 75%)",
    backgroundSize: "200% 100%",
    animation: "shimmer 1.4s infinite",
    borderRadius: 6,
  };
  return (
    <div style={{
      background: "#fff", borderRadius: 16, padding: 16,
      boxShadow: "0 1px 6px rgba(0,0,0,0.06)", marginBottom: 10,
    }}>
      <div style={{ display: "flex", gap: 12, marginBottom: 10 }}>
        <div style={{ ...shimmer, width: 56, height: 56, borderRadius: 10, flexShrink: 0 }} />
        <div style={{ flex: 1 }}>
          <div style={{ ...shimmer, height: 14, width: "70%", marginBottom: 8 }} />
          <div style={{ ...shimmer, height: 11, width: "40%" }} />
        </div>
      </div>
      <div style={{ ...shimmer, height: 11, width: "90%", marginBottom: 6 }} />
      <div style={{ ...shimmer, height: 11, width: "60%" }} />
    </div>
  );
}

// ─── 16. SUGG PRODUCT CARD ────────────────────────────────────────────────────

function SuggProductCard({ product, index, cat, allGroceryCats, onAddToList, addTarget }) {
  const [expanded, setExpanded] = useState(false);
  const [selectedCat, setSelectedCat] = useState(allGroceryCats[0] || "");
  const [added, setAdded] = useState(false);
  const color = SUGG_GRADE_COLORS[product.grade] || "#aaa";

  function handleAdd() {
    onAddToList(
      {
        name: product.name,
        nutriscore_grade: product.grade,
        gistScore: product.gistScore,
        image_url: product.img,
        brand: product.brand,
        additives: product.additives || [],
      },
      selectedCat
    );
    setAdded(true);
    setTimeout(() => setAdded(false), 1800);
  }

  return (
    <div style={{
      background: "#fff", borderRadius: 16,
      boxShadow: "0 1px 6px rgba(0,0,0,0.06)",
      marginBottom: 10, overflow: "hidden",
      animation: `fadeIn 0.3s ease ${index * 0.05}s both`,
    }}>
      <div
        onClick={() => setExpanded(e => !e)}
        style={{ padding: "14px 14px 10px", cursor: "pointer" }}
      >
        <div style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
          {product.img ? (
            <img
              src={product.img} alt={product.name}
              style={{
                width: 56, height: 56, objectFit: "contain",
                borderRadius: 10, border: "1px solid #f0ece4", flexShrink: 0,
              }}
            />
          ) : (
            <div style={{
              width: 56, height: 56, borderRadius: 10, flexShrink: 0,
              background: cat ? `linear-gradient(135deg, ${cat.g1}, ${cat.g2})` : "#eee",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontSize: 24,
            }}>
              {cat?.emoji || "🛒"}
            </div>
          )}
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{
              fontWeight: 700, fontSize: 14, color: "#2a2118",
              marginBottom: 3, whiteSpace: "nowrap",
              overflow: "hidden", textOverflow: "ellipsis",
            }}>
              {product.name}
            </div>
            <div style={{ fontSize: 11, color: "#888", marginBottom: 6 }}>{product.brand}</div>
            <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
              <SuggNutriArc grade={product.grade} size={38} />
              <div>
                <div style={{ fontSize: 11, fontWeight: 700, color }}>
                  {SUGG_RATINGS[product.grade] || "Unknown"}
                </div>
                {product.nova && (
                  <div style={{ fontSize: 10, color: "#aaa" }}>NOVA {product.nova}</div>
                )}
              </div>
              {product.gistScore !== null && product.gistScore !== undefined && (
                <RingScore score={product.gistScore} size={38} />
              )}
            </div>
          </div>
        </div>
      </div>
      {expanded && (
        <div style={{ padding: "0 14px 14px", borderTop: "1px solid #f5f2ec" }}>
          {product.ingredients && (
            <p style={{ fontSize: 11, color: "#888", lineHeight: 1.6, marginTop: 10, marginBottom: 0 }}>
              <strong>Ingredients:</strong> {product.ingredients}
              {product.ingredients.length >= 140 ? "…" : ""}
            </p>
          )}
          <AdditivesWarning additives={product.additives} />
          <div style={{ display: "flex", gap: 8, marginTop: 12, alignItems: "center" }}>
            <select
              value={selectedCat}
              onChange={e => setSelectedCat(e.target.value)}
              style={{
                flex: 1, padding: "7px 10px", borderRadius: 8,
                border: "1px solid #ddd", fontSize: 12,
                fontFamily: "'Lora', Georgia, serif",
              }}
            >
              {allGroceryCats.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
            <button
              onClick={handleAdd}
              style={{
                background: added ? "#1a9e3f" : "#7ac94b",
                color: "#fff", border: "none",
                borderRadius: 8, padding: "7px 14px",
                fontSize: 12, fontWeight: 700, cursor: "pointer",
                transition: "background 0.2s", whiteSpace: "nowrap",
              }}
            >
              {added ? "✓ Added" : `+ ${addTarget === "order" ? "Order" : "List"}`}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── 17. SUGGESTIONS PAGE ─────────────────────────────────────────────────────

function SuggestionsPage({ onAddToList, onAddToOrder, categories, orderCategories, onTabChange, currentTab }) {
  const [addTarget, setAddTarget] = useState("grocery");
  const [activeCat, setActiveCat] = useState(GROCERY_CATS[0]);
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(false);
  const cacheRef = useRef({});

  const cats = addTarget === "grocery" ? GROCERY_CATS : ORDER_CATS;
  const allCats = addTarget === "grocery" ? categories : orderCategories;

  useEffect(() => {
    setActiveCat(cats[0]);
  }, [addTarget]);

  useEffect(() => {
    if (!activeCat) return;
    const key = activeCat.tag;
    if (cacheRef.current[key]) {
      setProducts(cacheRef.current[key]);
      return;
    }
    setLoading(true);
    setProducts([]);
    fetchSuggestions(activeCat.tag).then(res => {
      cacheRef.current[key] = res;
      setProducts(res);
      setLoading(false);
    });
  }, [activeCat]);

  function handleAdd(item, catName) {
    if (addTarget === "order") onAddToOrder(item, catName);
    else onAddToList(item, catName);
  }

  return (
    <div style={{ minHeight: "100vh", background: "#f5f2ec", fontFamily: "'Lora', Georgia, serif", paddingBottom: 72 }}>
      {/* Header */}
      <div style={{
        background: "#2a2118", color: "#fff",
        padding: "14px 16px 10px",
        position: "sticky", top: 0, zIndex: 20,
      }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
          <h1 style={{ margin: 0, fontSize: 18, fontWeight: 800 }}>✨ Discover</h1>
          {/* Grocery / Order toggle */}
          <div style={{
            display: "flex", background: "rgba(255,255,255,0.12)",
            borderRadius: 8, overflow: "hidden",
          }}>
            {["grocery", "order"].map(t => (
              <button
                key={t}
                onClick={() => setAddTarget(t)}
                style={{
                  background: addTarget === t ? "#7ac94b" : "none",
                  border: "none", color: "#fff",
                  padding: "5px 12px", cursor: "pointer",
                  fontSize: 11, fontWeight: 700,
                  fontFamily: "'Lora', Georgia, serif",
                  transition: "background 0.15s",
                }}
              >{t === "grocery" ? "Grocery" : "Order"}</button>
            ))}
          </div>
        </div>
        {/* Category pills */}
        <div style={{
          display: "flex", gap: 8, overflowX: "auto",
          paddingBottom: 4, scrollbarWidth: "none",
        }}>
          {cats.map(c => (
            <button
              key={c.id}
              onClick={() => setActiveCat(c)}
              style={{
                background: activeCat?.id === c.id
                  ? `linear-gradient(135deg, ${c.g1}, ${c.g2})`
                  : "rgba(255,255,255,0.12)",
                border: "none", borderRadius: 20,
                padding: "6px 14px", color: "#fff",
                cursor: "pointer", whiteSpace: "nowrap",
                fontSize: 12, fontWeight: activeCat?.id === c.id ? 700 : 400,
                fontFamily: "'Lora', Georgia, serif",
                transition: "background 0.15s",
              }}
            >
              {c.emoji} {c.label}
            </button>
          ))}
        </div>
      </div>

      {/* Products */}
      <div style={{ padding: "14px 14px 0", maxWidth: 600, margin: "0 auto" }}>
        {loading
          ? Array.from({ length: 4 }).map((_, i) => <SuggSkeleton key={i} />)
          : products.length === 0
            ? (
              <div style={{ textAlign: "center", color: "#bbb", padding: "40px 0", fontSize: 14 }}>
                No products found for this category.
              </div>
            )
            : products.map((p, i) => (
              <SuggProductCard
                key={i}
                product={p}
                index={i}
                cat={activeCat}
                allGroceryCats={allCats}
                onAddToList={handleAdd}
                addTarget={addTarget}
              />
            ))
        }
      </div>

      <TabBar currentTab={currentTab} onTabChange={onTabChange} />
    </div>
  );
}

// ─── 18. ORDER LIST PAGE ──────────────────────────────────────────────────────

function OrderListPage({
  orderList, onAddToOrder, onToggle, onRemove, onUpdateQty,
  onAddCategory, onClearChecked, onTabChange, currentTab,
}) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [searchError, setSearchError] = useState("");
  const debounceRef = useRef(null);

  const [scannerOpen, setScannerOpen] = useState(false);
  const [scannedProduct, setScannedProduct] = useState(null);
  const [scanLoading, setScanLoading] = useState(false);
  const [scanError, setScanError] = useState(null);

  const [addingCat, setAddingCat] = useState(false);
  const [newCat, setNewCat] = useState("");

  // Independent search debounce
  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (!query.trim()) { setResults([]); setSearchError(""); return; }
    setSearching(true);
    debounceRef.current = setTimeout(async () => {
      try {
        const res = await fetchBySearch(query.trim());
        setResults(res);
        setSearchError(res.length === 0 ? "No products found." : "");
      } catch {
        setSearchError("Search failed.");
      } finally { setSearching(false); }
    }, 500);
    return () => clearTimeout(debounceRef.current);
  }, [query]);

  async function handleBarcodeScan(barcode) {
    setScannerOpen(false);
    setScanLoading(true);
    setScanError(null);
    setScannedProduct(null);
    const product = await fetchByBarcode(barcode);
    setScanLoading(false);
    if (!product) setScanError(barcode);
    else setScannedProduct(product);
  }

  const catNames = Object.keys(orderList).length > 0 ? Object.keys(orderList) : ["General"];
  const checkedCount = Object.values(orderList).flat().filter(i => i.checked).length;
  const showDropdown = query.trim().length > 0;

  return (
    <div style={{ minHeight: "100vh", background: "#f5f2ec", fontFamily: "'Lora', Georgia, serif", paddingBottom: 72 }}>
      {/* Header */}
      <div style={{
        background: "#2a2118", color: "#fff",
        padding: "0 16px",
        position: "sticky", top: 0, zIndex: 20,
      }}>
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "14px 0 10px",
        }}>
          <div style={{ fontWeight: 800, fontSize: 18 }}>🛒 Order List</div>
          <button
            onClick={() => setScannerOpen(true)}
            style={{
              background: "rgba(255,255,255,0.1)", border: "none",
              color: "#fff", borderRadius: 8, padding: "6px 12px",
              cursor: "pointer", fontSize: 16,
            }}
          >📷</button>
        </div>
        {/* Search */}
        <div style={{ position: "relative", paddingBottom: 12 }}>
          <input
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder="Search products to add…"
            style={{
              width: "100%", boxSizing: "border-box",
              background: "rgba(255,255,255,0.12)",
              border: "1px solid rgba(255,255,255,0.2)",
              borderRadius: 10, padding: "10px 40px 10px 14px",
              color: "#fff", fontSize: 14, outline: "none",
              fontFamily: "'Lora', Georgia, serif",
            }}
          />
          {searching && (
            <div style={{
              position: "absolute", right: 12, top: "50%",
              transform: "translateY(-50%)",
              width: 16, height: 16, border: "2px solid #7ac94b",
              borderTopColor: "transparent", borderRadius: "50%",
              animation: "spin 0.6s linear infinite",
            }} />
          )}
        </div>
      </div>

      {/* Search dropdown */}
      {showDropdown && (
        <div style={{
          background: "#fff", boxShadow: "0 4px 20px rgba(0,0,0,0.12)",
          borderRadius: "0 0 12px 12px", overflow: "hidden",
          position: "sticky", top: 90, zIndex: 15,
        }}>
          {searchError && (
            <div style={{ padding: "14px", color: "#888", fontSize: 13, textAlign: "center" }}>
              {searchError}
            </div>
          )}
          {results.map((item, i) => (
            <OrderSearchRow
              key={i}
              item={item}
              categories={catNames}
              onAdd={(item, cat) => { onAddToOrder(item, cat); setQuery(""); setResults([]); }}
            />
          ))}
        </div>
      )}

      {/* Order list content */}
      <div style={{ padding: "16px 14px", maxWidth: 600, margin: "0 auto" }}>
        {checkedCount > 0 && (
          <button
            onClick={onClearChecked}
            style={{
              background: "#fff", border: "1px solid #ddd",
              borderRadius: 8, padding: "6px 14px",
              fontSize: 12, color: "#888", cursor: "pointer",
              marginBottom: 14, display: "block",
            }}
          >
            Clear {checkedCount} checked item{checkedCount !== 1 ? "s" : ""}
          </button>
        )}

        {Object.entries(orderList).map(([catName, items]) => (
          <div key={catName} style={{ marginBottom: 16 }}>
            <div style={{
              fontWeight: 700, fontSize: 14, color: "#2a2118",
              padding: "6px 2px", marginBottom: 6,
            }}>
              {catName}
              <span style={{ color: "#bbb", fontWeight: 400, marginLeft: 8, fontSize: 12 }}>
                {items.length}
              </span>
            </div>
            <div style={{
              background: "#fff", borderRadius: 12,
              boxShadow: "0 1px 6px rgba(0,0,0,0.06)",
              overflow: "hidden",
            }}>
              {items.length === 0 ? (
                <div style={{ padding: "12px 16px", color: "#ccc", fontSize: 13, textAlign: "center" }}>
                  No items yet
                </div>
              ) : (
                items.map((item, idx) => (
                  <OrderItemRow
                    key={idx}
                    item={item}
                    onToggle={() => onToggle(catName, idx)}
                    onRemove={() => onRemove(catName, idx)}
                    onUpdateQty={qty => onUpdateQty(catName, idx, qty)}
                  />
                ))
              )}
            </div>
          </div>
        ))}

        {/* Add category */}
        {addingCat ? (
          <form
            onSubmit={e => { e.preventDefault(); onAddCategory(newCat); setAddingCat(false); setNewCat(""); }}
            style={{ display: "flex", gap: 8, marginTop: 8 }}
          >
            <input
              autoFocus
              value={newCat}
              onChange={e => setNewCat(e.target.value)}
              placeholder="Category name"
              style={{
                flex: 1, border: "1px solid #ddd", borderRadius: 8,
                padding: "8px 12px", fontSize: 14,
                fontFamily: "'Lora', Georgia, serif", outline: "none",
              }}
            />
            <button
              type="submit"
              style={{
                background: "#7ac94b", color: "#fff", border: "none",
                borderRadius: 8, padding: "8px 14px", fontWeight: 700,
                cursor: "pointer", fontSize: 14,
              }}
            >Add</button>
            <button
              type="button"
              onClick={() => { setAddingCat(false); setNewCat(""); }}
              style={{
                background: "#eee", border: "none", borderRadius: 8,
                padding: "8px 10px", cursor: "pointer", fontSize: 14,
              }}
            >✕</button>
          </form>
        ) : (
          <button
            onClick={() => setAddingCat(true)}
            style={{
              width: "100%", background: "none",
              border: "2px dashed #ddd", borderRadius: 10,
              padding: "10px", color: "#bbb", fontSize: 13,
              cursor: "pointer", marginTop: 8,
            }}
          >
            + Add Category
          </button>
        )}
      </div>

      <TabBar currentTab={currentTab} onTabChange={onTabChange} />

      {scannerOpen && (
        <BarcodeScanner
          onDetected={handleBarcodeScan}
          onClose={() => setScannerOpen(false)}
        />
      )}

      {(scannedProduct || scanLoading || scanError) && (
        <ScannedProductModal
          product={scannedProduct}
          loading={scanLoading}
          error={scanError}
          categories={catNames}
          onAdd={(item, cat) => { onAddToOrder(item, cat); setScannedProduct(null); setScanError(null); }}
          onClose={() => { setScannedProduct(null); setScanError(null); }}
        />
      )}
    </div>
  );
}

// ─── 19. ORDER SEARCH ROW ─────────────────────────────────────────────────────

function OrderSearchRow({ item, categories, onAdd }) {
  const [selectedCat, setSelectedCat] = useState(categories[0] || "");
  const [hovered, setHovered] = useState(false);

  useEffect(() => {
    setSelectedCat(categories[0] || "");
  }, [categories]);

  return (
    <div
      onMouseEnter={e => { e.currentTarget.style.background = "#f9f7f3"; setHovered(true); }}
      onMouseLeave={e => { e.currentTarget.style.background = "#fff"; setHovered(false); }}
      style={{
        borderBottom: "1px solid #f0ece4",
        padding: "10px 14px",
        transition: "background 0.15s",
      }}
    >
      <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
        {item.image_url && (
          <img
            src={item.image_url} alt={item.name}
            style={{ width: 44, height: 44, objectFit: "contain", borderRadius: 6, flexShrink: 0 }}
          />
        )}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontWeight: 600, fontSize: 13, color: "#2a2118",
            whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
          }}>
            {item.name}
          </div>
          <div style={{ fontSize: 11, color: "#888", marginBottom: 4 }}>{item.brand}</div>
          <div style={{ display: "flex", gap: 5 }}>
            <HealthBadge grade={item.nutriscore_grade} />
            <GistScoreBadge score={item.gistScore} />
          </div>
        </div>
      </div>
      <div style={{ display: "flex", gap: 6, marginTop: 8 }}>
        <select
          value={selectedCat}
          onChange={e => setSelectedCat(e.target.value)}
          onClick={e => e.stopPropagation()}
          style={{
            flex: 1, padding: "6px 8px", borderRadius: 6,
            border: "1px solid #ddd", fontSize: 12,
            fontFamily: "'Lora', Georgia, serif",
          }}
        >
          {categories.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
        <button
          onClick={() => onAdd(item, selectedCat)}
          style={{
            background: "#7ac94b", color: "#fff", border: "none",
            borderRadius: 6, padding: "6px 12px", fontSize: 12,
            fontWeight: 700, cursor: "pointer",
          }}
        >+ Add</button>
      </div>
    </div>
  );
}

// ─── ORDER ITEM ROW ───────────────────────────────────────────────────────────

function OrderItemRow({ item, onToggle, onRemove, onUpdateQty }) {
  const [hovered, setHovered] = useState(false);
  return (
    <div
      onMouseEnter={e => { e.currentTarget.style.background = "#f9f7f3"; setHovered(true); }}
      onMouseLeave={e => { e.currentTarget.style.background = "#fff"; setHovered(false); }}
      style={{
        display: "flex", alignItems: "center", gap: 10,
        padding: "10px 14px", borderBottom: "1px solid #f5f2ec",
        transition: "background 0.15s",
      }}
    >
      <input
        type="checkbox"
        checked={item.checked}
        onChange={onToggle}
        style={{ width: 18, height: 18, accentColor: "#7ac94b", cursor: "pointer", flexShrink: 0 }}
      />
      <span style={{
        flex: 1, fontSize: 14,
        color: item.checked ? "#bbb" : "#2a2118",
        textDecoration: item.checked ? "line-through" : "none",
      }}>
        {item.name}
      </span>
      {item.nutri && (
        <span style={{
          background: nutriColor(item.nutri), color: "#fff",
          borderRadius: 4, padding: "1px 6px", fontSize: 10, fontWeight: 700, flexShrink: 0,
        }}>
          {item.nutri.toUpperCase()}
        </span>
      )}
      {/* Qty stepper */}
      <div style={{ display: "flex", alignItems: "center", gap: 4, flexShrink: 0 }}>
        <button
          onClick={() => onUpdateQty((item.qty || 1) - 1)}
          style={{
            width: 24, height: 24, border: "1px solid #ddd",
            borderRadius: "50%", background: "#f5f2ec",
            cursor: "pointer", fontSize: 14, color: "#666",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}
        >−</button>
        <span style={{ fontSize: 13, fontWeight: 600, minWidth: 20, textAlign: "center" }}>
          {item.qty || 1}
        </span>
        <button
          onClick={() => onUpdateQty((item.qty || 1) + 1)}
          style={{
            width: 24, height: 24, border: "1px solid #ddd",
            borderRadius: "50%", background: "#f5f2ec",
            cursor: "pointer", fontSize: 14, color: "#666",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}
        >+</button>
      </div>
      {hovered && (
        <button
          onClick={onRemove}
          style={{
            background: "none", border: "none", color: "#e63c2f",
            cursor: "pointer", fontSize: 16, padding: "0 2px", flexShrink: 0,
          }}
        >×</button>
      )}
    </div>
  );
}

// ─── MOUNT ────────────────────────────────────────────────────────────────────

const rootEl = document.getElementById("root");
if (rootEl) {
  ReactDOM.createRoot(rootEl).render(<App />);
}
