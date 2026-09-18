// The T047 launch audit, rewritten by W067 from the old literal grep ("calorie/macro entry") to THE SEVEN NO-GRADE CLAUSES (Flow 4,
// A16 — owner-ratified 2026-09-10; kept unchanged by the nutrition addendum, ratified 2026-09-18) plus A21.13's NOT BUILDING list.
// "Nothing rejected exists" — and nothing rejected is PREPARED FOR (CLAUDE.md rule 10). Every check is a scan of shipped source with
// comments stripped (a comment that says "never a barcode" is the rule, not a violation); string literals stay, because copy ships.
// Run: node shared/scripts/launch-audit.mjs   Exits 1 on any finding. CI runs it in the contracts job.
// SPEC: Flow 4 clauses ①–⑦ (each names its mechanism; this is ⑦'s, and the second line of defence for ① ② ③ ④ ⑤) · A21.13 · T047 · W067

import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const rel = (file) => relative(repoRoot, file).replaceAll("\\", "/");
const SKIP = new Set(["node_modules", ".next", ".build", "DerivedData", "generated", "Generated", "test-results", "playwright-report", ".blob-dev"]);

function walk(dir, out = []) {
  if (!existsSync(dir)) return out;
  for (const entry of readdirSync(dir)) {
    if (SKIP.has(entry) || entry.endsWith(".xcodeproj")) continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) walk(full, out);
    else if (/\.(ts|tsx|swift|css|json|mjs|yml)$/.test(entry)) out.push(full);
  }
  return out;
}

// Comments out, newlines kept (so a finding still names its line); a "//" inside a string or a URL is left alone
function code(file) {
  const text = readFileSync(file, "utf8");
  if (file.endsWith(".json")) return text;
  const withoutBlocks = text.replace(/\/\*[\s\S]*?\*\//g, (block) => block.replace(/[^\n]/g, " "));
  if (file.endsWith(".css")) return withoutBlocks;
  return withoutBlocks.split("\n").map((line) => line.replace(/(^|[^:"'`\\])\/\/.*$/, "$1")).join("\n");
}

const shipped = [...walk(join(repoRoot, "web", "src")), ...walk(join(repoRoot, "ios", "Crew")), ...walk(join(repoRoot, "shared", "seed")), ...walk(join(repoRoot, "shared", "copy"))];
const sources = new Map(shipped.map((file) => [rel(file), code(file)]));
const findings = [];
const passed = [];

// Every line of every file under `where` (a list of path prefixes; [] = everything shipped) that matches `pattern`
function scan(clause, what, pattern, where = [], except = []) {
  let hits = 0;
  for (const [path, text] of sources) {
    if (where.length > 0 && !where.some((prefix) => path.startsWith(prefix))) continue;
    if (except.some((prefix) => path.startsWith(prefix))) continue;
    text.split("\n").forEach((line, index) => {
      if (!pattern.test(line)) return;
      hits += 1;
      findings.push(`${clause}  ${path}:${index + 1}  ${what} — ${line.trim().slice(0, 120)}`);
    });
  }
  if (hits === 0) passed.push(`${clause}  ${what}`);
}

function absent(clause, what, paths) {
  const present = paths.filter((path) => existsSync(join(repoRoot, path)));
  for (const path of present) findings.push(`${clause}  ${path}  ${what} — this path must not exist`);
  if (present.length === 0) passed.push(`${clause}  ${what}`);
}

const NUTRITION_UI = ["web/src/components/nutrition/", "web/src/app/(app)/nutrition/", "ios/Crew/Features/Nutrition/"];
const NUTRITION_SERVER = ["web/src/lib/nutrition-", "web/src/lib/validate-nutrition", "web/src/lib/documents-nutrition", "web/src/app/api/v1/nutrition/"];
const NUTRITION_PHONE = ["ios/Crew/Storage/Nutrition", "ios/Crew/Storage/ModelsNutrition", "ios/Crew/Api/ApiNutrition", "ios/Crew/Engine/MacroDay", "ios/Crew/Engine/NutritionTargets"];
const SOCIAL = ["web/src/lib/crew", "web/src/lib/posts", "web/src/lib/reactions", "web/src/lib/blocks", "web/src/app/api/v1/crews/", "web/src/app/api/v1/posts/", "web/src/components/Crew", "web/src/components/StreamList", "ios/Crew/Features/Crew/", "ios/Crew/Api/ApiCrews"];

// ① no food, meal or day is scored, rated, ranked or labelled — not in the UI, not in the seed, not in a sort order
scan("①", "a quality word on a food, a meal or a day", /\b(healthy|unhealthy|healthier|clean eating|junk|guilt|cheat (meal|day)|good food|bad food|superfood)\b/i, [...NUTRITION_UI, ...NUTRITION_SERVER, "shared/seed/fast-food.json", "shared/copy/"]);
scan("①", "a score, grade, rating or rank field on nutrition data", /\b(score|grade|rating|rank|stars?|healthScore|nutriScore)\b\s*[:=?]/i, [...NUTRITION_UI, ...NUTRITION_SERVER, ...NUTRITION_PHONE, "shared/seed/fast-food.json"]);
// ② over-target is never red, never an alert, never a notification; no semantic token and no ember on a nutrition surface
scan("②", "a semantic or ember token on a nutrition surface", /(EmberColors\.(danger|success|missedGray|ember|emberText|emberTint)\b|className="[^"]*\b(danger|missed|ember-text)\b|--ember-(danger|success|missed-gray|ember)\b)/, NUTRITION_UI);
scan("②", "an alert, a modal or a notification about macros", /\.(alert|confirmationDialog)\(|window\.(alert|confirm)\(|UNMutableNotificationContent|sendPush|apns/i, [...NUTRITION_UI, ...NUTRITION_SERVER, ...NUTRITION_PHONE]);
scan("②", "a notification that mentions nutrition", /\b(macro|protein|carbs|calorie|nutrition|meal log)/i, ["web/src/lib/notification", "web/src/lib/push", "web/src/app/api/cron/", "ios/Crew/PushRegistrar"]);
// ③ a macro entry earns no XP, breaks no streak, consumes no shield, unlocks no achievement
scan("③", "nutrition code that reaches the game state", /(gamification-store|recomputeAndStore|achievement-facts|GamificationLocal|GamificationEngine\.apply|awardXp|xpFor|LocalGamificationState)/, [...NUTRITION_SERVER, "ios/Crew/Storage/Nutrition", "ios/Crew/Features/Nutrition/", "web/src/components/nutrition/"]);
// ④ a macro number never appears in the feed, on a profile or in the pulse; nutrition is never a post
scan("④", "social code that reads nutrition data", /(mealLogs|savedMeals|nutritionTargets|dayTemplates|nutrition-|LocalMealLog|LocalSavedMeal|LocalNutritionTargets|MacroDay\.|NutritionLocal)/, SOCIAL);
scan("④", "nutrition code that writes a post", /(insertOne\([^)]*post|createPost|LocalPost\(|posts\(\)\)\.insert)/, [...NUTRITION_SERVER, "ios/Crew/Storage/Nutrition", "ios/Crew/Features/Nutrition/"]);
// ⑤ bounds validation and nothing else: no plausibility check on an entered number
scan("⑤", "a plausibility check or an under-reporting warning", /(seems? (too )?(low|high)|plausib|anomal|under-?report|are you sure|unusually|suspicious|double-check)/i, [...NUTRITION_UI, ...NUTRITION_SERVER, ...NUTRITION_PHONE]);
// ⑥ superseded by A22: there is no plate journal left to keep numberless — so none may come back
absent("⑥", "the plate journal stays removed (A22)", ["web/src/components/PostComposer.tsx", "web/src/app/(app)/post", "web/src/lib/engine/meal-tag.ts", "ios/Crew/Engine/MealTag.swift", "ios/Crew/Features/Post/PostComposer.swift", "ios/Crew/Features/Post/NutritionPostScreen.swift"]);
// ⑦ barcode scanning, food recognition, food search and third-party nutrition data stay rejected — and are never prepared for
scan("⑦", "barcode scanning or food recognition", /(barcode|AVCaptureMetadataOutput|VNRecognize|VNClassify|import Vision|import CoreML|MLModel|BarcodeDetector)/i);
scan("⑦", "a third-party nutrition API or a food search", /(openfoodfacts|nutritionix|edamam|fatsecret|fdc\.nal\.usda|api\.nal\.usda|spoonacular|searchFoods?|foodSearch|food-search)/i);

// A21.13 — NOT BUILDING (MVP)
absent("A21.13", "no public feed, leaderboard, comments, DMs or chat routes", ["web/src/app/api/v1/feed", "web/src/app/api/v1/leaderboard", "web/src/app/api/v1/comments", "web/src/app/api/v1/messages", "web/src/app/api/v1/crews/[id]/messages", "web/src/app/(app)/feed", "web/src/app/(app)/leaderboard", "ios/Crew/Features/Feed", "ios/Crew/Features/Chat"]);
scan("A21.13", "a leaderboard, a public feed, dating or DMs", /(leaderboard|publicFeed|explore feed|dating|matchmaking|directMessage|sendMessage\()/i);
scan("A21.13", "supersets, or A15's change-today's-workout sheet", /(superset|Change today's workout|what do you have today|equipmentTier|equipmentAccess)/i);
scan("A21.13", "exercise media (A13 is lawyer-gated — not in MVP)", /(AVPlayer|VideoPlayer|\.mp4|exercise-media|exerciseVideo|<video)/i);
scan("A21.13", "web push", /(serviceWorker|PushManager|web-push|pushManager|Notification\.requestPermission)/);
absent("A21.13", "no Android project", ["android", "app/build.gradle", "AndroidManifest.xml"]);

for (const line of passed) console.log(`ok     ${line}`);
for (const finding of findings) console.log(`AUDIT  ${finding}`);
if (findings.length > 0) { console.log(`launch-audit: ${findings.length} finding(s) across ${sources.size} shipped files`); process.exit(1); }
console.log(`launch-audit: clean — ${passed.length} checks over ${sources.size} shipped files (the seven no-grade clauses + A21.13)`);
