// SPEC: Appendix A 2026-09-18 A24 (4) — THE DIFF. Collects the tour's shots out of the storyboard, compares each with its committed
// baseline under a pixel tolerance, and writes the `ui-tour` artifact: <out>/<tour class>/NN_<tab>_<screen>_<state>.png · TOUR.md ·
// CHANGES.md (changed · expected drift · new · removed · unchanged). Zero dependencies: the PNG decode is node:zlib plus the five
// PNG row filters, so no devDependency joins the fixed list. It REPORTS and always exits 0 — a changed screen is news for the
// reviewer, not a red build. Usage: node ios/scripts/tour-diff.mjs <storyboard-dir> <baselines-dir> <ui-tour-out-dir>
import { copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { inflateSync } from "node:zlib";

const [storyboardDir, baselinesDir, outDir] = process.argv.slice(2);
if (!storyboardDir || !baselinesDir || !outDir) {
  console.error("usage: node ios/scripts/tour-diff.mjs <storyboard-dir> <baselines-dir> <ui-tour-out-dir>");
  process.exit(2);
}

// The tolerance. A channel must move by more than this to count (antialiasing and compression noise sit far below it), and more
// than this share of the screen must move before the screen is called changed.
const channelTolerance = 24;
const changedShare = 0.001;

// Screens that render a weekday, a date, an elapsed time, a running timer or a random invite code. The spec defines no frozen app
// clock and A24 adds none, so a difference on one of these is EXPECTED DRIFT, reported apart from a real change.
const driftScreens = [/^home_home_/, /^home_bonus_sheet/, /^plan_week_/, /^plan_days_sheet/, /^progress_/, /^crew_invite_sheet/, /^crew_stream_/, /^crew_react_dialog/, /^session_logger_midset/, /^session_celebration_/, /^session_swap_sheet/, /^session_discard_dialog/, /^settings_pause_/, /^home_reminder_sheet/];
const driftProne = (file) => driftScreens.some((pattern) => pattern.test(file.replace(/^\d{2}_/, "")));

function paeth(a, b, c) {
  const p = a + b - c;
  const pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
  return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
}

// 8- or 16-bit, truecolour with or without alpha, non-interlaced — what a simulator screenshot is. Anything else returns null.
function decodePng(path) {
  const data = readFileSync(path);
  if (data.length < 33 || data.readUInt32BE(0) !== 0x89504e47) return null;
  let offset = 8, width = 0, height = 0, depth = 0, colorType = 0, interlace = 0;
  const idat = [];
  while (offset + 8 <= data.length) {
    const length = data.readUInt32BE(offset);
    const type = data.toString("latin1", offset + 4, offset + 8);
    const body = data.subarray(offset + 8, offset + 8 + length);
    if (type === "IHDR") { width = body.readUInt32BE(0); height = body.readUInt32BE(4); depth = body[8]; colorType = body[9]; interlace = body[12]; }
    if (type === "IDAT") idat.push(body);
    if (type === "IEND") break;
    offset += 12 + length;
  }
  if ((colorType !== 2 && colorType !== 6) || (depth !== 8 && depth !== 16) || interlace !== 0) return null;
  const channels = colorType === 6 ? 4 : 3;
  const bytesPerPixel = channels * (depth / 8);
  const stride = width * bytesPerPixel;
  const raw = inflateSync(Buffer.concat(idat));
  const pixels = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y += 1) {
    const filter = raw[y * (stride + 1)];
    const rowIn = y * (stride + 1) + 1;
    const rowOut = y * stride;
    for (let x = 0; x < stride; x += 1) {
      const left = x >= bytesPerPixel ? pixels[rowOut + x - bytesPerPixel] : 0;
      const up = y > 0 ? pixels[rowOut - stride + x] : 0;
      const upLeft = y > 0 && x >= bytesPerPixel ? pixels[rowOut - stride + x - bytesPerPixel] : 0;
      const predicted = filter === 0 ? 0 : filter === 1 ? left : filter === 2 ? up : filter === 3 ? (left + up) >> 1 : paeth(left, up, upLeft);
      pixels[rowOut + x] = (raw[rowIn + x] + predicted) & 0xff;
    }
  }
  return { width, height, bytesPerPixel, channels, step: depth / 8, pixels };
}

// → { verdict: "same" | "changed", detail }
function compare(currentPath, baselinePath) {
  if (readFileSync(currentPath).equals(readFileSync(baselinePath))) return { verdict: "same", detail: "identical bytes" };
  const current = decodePng(currentPath), baseline = decodePng(baselinePath);
  if (!current || !baseline) return { verdict: "changed", detail: "not a PNG this script decodes — compared as bytes" };
  if (current.width !== baseline.width || current.height !== baseline.height) return { verdict: "changed", detail: `size ${baseline.width}×${baseline.height} → ${current.width}×${current.height}` };
  let moved = 0;
  for (let pixel = 0; pixel < current.width * current.height; pixel += 1) {
    for (let channel = 0; channel < 3; channel += 1) {
      const a = current.pixels[pixel * current.bytesPerPixel + channel * current.step];
      const b = baseline.pixels[pixel * baseline.bytesPerPixel + channel * baseline.step];
      if (Math.abs(a - b) > channelTolerance) { moved += 1; break; }
    }
  }
  const share = moved / (current.width * current.height);
  const detail = `${(share * 100).toFixed(2)}% of pixels moved`;
  return { verdict: share > changedShare ? "changed" : "same", detail };
}

function tourShots(root) {
  if (!existsSync(root)) return [];
  const shots = [];
  for (const dir of readdirSync(root).filter((entry) => /^tour/i.test(entry) && statSync(join(root, entry)).isDirectory())) {
    for (const file of readdirSync(join(root, dir)).filter((entry) => entry.toLowerCase().endsWith(".png"))) shots.push(`${dir}/${file}`);
  }
  return shots.sort();
}

const current = tourShots(storyboardDir);
const baselines = tourShots(baselinesDir);
const groups = { changed: [], drift: [], added: [], removed: [], unchanged: [] };
mkdirSync(outDir, { recursive: true });
for (const shot of current) {
  mkdirSync(join(outDir, shot.split("/")[0]), { recursive: true });
  copyFileSync(join(storyboardDir, shot), join(outDir, shot));
  if (!baselines.includes(shot)) { groups.added.push(`${shot}`); continue; }
  const { verdict, detail } = compare(join(storyboardDir, shot), join(baselinesDir, shot));
  if (verdict === "same") groups.unchanged.push(`${shot} — ${detail}`);
  else if (driftProne(shot.split("/")[1])) groups.drift.push(`${shot} — ${detail}`);
  else groups.changed.push(`${shot} — ${detail}`);
}
for (const shot of baselines) if (!current.includes(shot)) groups.removed.push(shot);
if (existsSync(join(storyboardDir, "TOUR.md"))) copyFileSync(join(storyboardDir, "TOUR.md"), join(outDir, "TOUR.md"));

const summary = `${groups.changed.length} changed · ${groups.drift.length} expected drift · ${groups.added.length} new · ${groups.removed.length} removed · ${groups.unchanged.length} unchanged`;
const section = (title, rows) => [`## ${title} (${rows.length})`, "", ...(rows.length > 0 ? rows.map((row) => `- ${row}`) : ["- none"]), ""];
const lines = [
  "# UI tour — changes against design/baselines/",
  "",
  `SUMMARY: ${summary}`,
  "",
  baselines.length === 0 ? "No baselines are committed yet — every screen is new. Approve them with /approve-screens." : groups.changed.length === 0 && groups.added.length === 0 && groups.removed.length === 0 ? "No visual changes." : "Visual changes — view the changed, new and removed screens before any UI work.",
  "",
  ...section("Changed", groups.changed),
  ...section("Changed — expected drift (the screen renders a weekday, a date, a timer or a random code)", groups.drift),
  ...section("New (no baseline)", groups.added),
  ...section("Removed (a baseline the tour no longer produced — the step's element was missing, or the flow was skipped)", groups.removed),
  ...section("Unchanged", groups.unchanged),
  `Tolerance: a channel moves by more than ${channelTolerance}/255, on more than ${changedShare * 100}% of the screen.`,
];
writeFileSync(join(outDir, "CHANGES.md"), `${lines.join("\n")}\n`);
console.log(`tour-diff: ${current.length} shot(s) — ${summary}`);
