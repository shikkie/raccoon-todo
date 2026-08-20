export default function RaccoonMascot({ mood = "happy" }) {
  const sleepy = mood === "sleepy";

  return (
    <svg
      className="mascot"
      viewBox="0 0 220 210"
      role="img"
      aria-label="A round cartoon raccoon"
    >
      <ellipse cx="150" cy="168" rx="46" ry="18" fill="#3a2f28" opacity="0.35" />
      <path
        d="M150 96c28 8 46 36 42 62-18 6-38 8-56 4-10-22-6-48 14-66z"
        fill="#6b5a4a"
      />
      <path d="M148 118c16 4 28 16 32 30" fill="none" stroke="#4a3d34" strokeWidth="7" />
      <path d="M154 132c12 3 20 12 22 22" fill="none" stroke="#cfc3b4" strokeWidth="7" />
      <path d="M160 146c8 2 12 8 14 14" fill="none" stroke="#4a3d34" strokeWidth="7" />
      <ellipse cx="108" cy="138" rx="58" ry="50" fill="#8a7460" />
      <ellipse cx="108" cy="158" rx="36" ry="22" fill="#f3d5b5" />
      <ellipse cx="72" cy="54" rx="18" ry="22" fill="#6b5a4a" />
      <ellipse cx="144" cy="54" rx="18" ry="22" fill="#6b5a4a" />
      <ellipse cx="72" cy="56" rx="10" ry="13" fill="#f3d5b5" />
      <ellipse cx="144" cy="56" rx="10" ry="13" fill="#f3d5b5" />
      <ellipse cx="108" cy="92" rx="56" ry="50" fill="#8a7460" />
      <path
        d="M54 90c18-18 40-16 54-2 14-14 36-16 54 2 4 18-10 32-26 34-14 2-22-6-28-6s-14 8-28 6c-16-2-30-16-26-34z"
        fill="#2b241f"
      />
      {sleepy ? (
        <>
          <path d="M84 90c8 8 16 8 24 0" fill="none" stroke="#f7efe4" strokeWidth="4" strokeLinecap="round" />
          <path d="M108 90c8 8 16 8 24 0" fill="none" stroke="#f7efe4" strokeWidth="4" strokeLinecap="round" />
        </>
      ) : (
        <>
          <circle cx="90" cy="92" r="8" fill="#f7efe4" />
          <circle cx="126" cy="92" r="8" fill="#f7efe4" />
          <circle cx="91" cy="93" r="4" fill="#1a1614" />
          <circle cx="127" cy="93" r="4" fill="#1a1614" />
          <circle cx="93" cy="91" r="1.4" fill="#fff" />
          <circle cx="129" cy="91" r="1.4" fill="#fff" />
        </>
      )}
      <ellipse cx="108" cy="108" rx="16" ry="12" fill="#f3d5b5" />
      <ellipse cx="108" cy="106" rx="7" ry="5" fill="#1a1614" />
      <path
        d="M100 116c6 8 16 8 22 0"
        fill="none"
        stroke="#7a4a3a"
        strokeWidth="3"
        strokeLinecap="round"
      />
      <ellipse cx="78" cy="176" rx="16" ry="10" fill="#6b5a4a" />
      <ellipse cx="138" cy="176" rx="16" ry="10" fill="#6b5a4a" />
      <circle cx="70" cy="174" r="3" fill="#f3d5b5" />
      <circle cx="78" cy="171" r="3" fill="#f3d5b5" />
      <circle cx="86" cy="174" r="3" fill="#f3d5b5" />
    </svg>
  );
}
