// Swift cross-reference check — the compile errors this repo has actually shipped to the macOS runner, caught on a machine
// without a compiler. The Swift files are never compiled here (Windows, no Xcode; the Linux toolchain has no SwiftUI or
// SwiftData), so a screen edited in one file and called from another meets the compiler only on GitHub's macOS job, ten
// minutes later. Every diagnostic that job has produced so far was one of four kinds, and all four are visible from the
// source text alone:
//   1. `Type.member` where the type is declared in ios/ and has no such member (an enum case removed, a static renamed)
//   2. `Type(...)` / `Type.f(...)` whose argument labels match none of the type's initializers or functions (a parameter
//      added, removed or renamed — including a struct's memberwise initializer, derived here by Swift's rules)
//   3. a module type that shadows a SwiftUI one (the module's `Stepper`), so an unqualified call meant for SwiftUI's init
//      matches nothing — the finding says so
//   4. `Type.shared.method(...)` — an INSTANCE call through the type's singleton — whose labels match none of the type's
//      functions. The reference scan used to stop at `.shared` (a member that exists) and never looked at the call after
//      it; run 34491587098 died on exactly that: OnboardingModelAuth passed AuthStore.shared.signInWithApple a label the
//      function does not take, and this check said "clean"
// Precision over recall: only types declared under ios/ are checked, a reference passes when ANY declaration of that name
// accepts it, closure parameters may be supplied as trailing closures, and enum-case payloads are not label-checked.
// Strings and comments are blanked before scanning. Run: node shared/scripts/swift-xref.mjs [ios-dir]   Exits 1 on a finding.

import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const iosDir = resolve(process.argv[2] ?? join(repoRoot, "ios"));
const MODULE_NAMES = new Set(["Crew", "Foundation", "SwiftUI", "SwiftData", "XCTest", "UIKit", "Combine", "Darwin", "Dispatch", "PhotosUI", "UserNotifications", "AuthenticationServices", "Security", "OSLog", "CoreData", "Testing", "AVFoundation", "StoreKit", "Observation"]);
const SWIFTUI_NAMES = new Set(["Stepper", "Toggle", "Section", "Label", "Button", "Text", "Image", "List", "Form", "Slider", "Picker", "Link", "Menu", "Group", "Table", "Grid", "Divider", "Spacer", "Color", "Font", "Path", "Shape", "Animation", "Alert", "ProgressView", "Gauge", "TextField", "SecureField", "DatePicker", "Capsule", "Circle", "Rectangle", "EmptyView", "AnyView", "State", "Binding", "Environment", "Namespace", "Angle", "Alignment", "Axis", "Edge", "Transaction", "Task", "Timer", "Notification", "Data", "Date", "URL", "Bundle", "Locale", "Calendar", "Measurement", "ScrollView", "NavigationStack", "NavigationLink", "TabView", "Sheet", "Chart", "Canvas", "TimelineView", "GeometryReader", "LazyVStack", "LazyHStack", "VStack", "HStack", "ZStack"]);
const WRAPPERS_REQUIRED = new Set(["Binding", "ObservedObject", "Bindable"]);
const MODIFIER = /^(?:public|private(?:\(set\))?|fileprivate(?:\(set\))?|internal|package|open|static|class|final|lazy|weak|unowned|override|nonisolated|mutating|nonmutating|indirect|dynamic|optional|required|convenience|isolated)$/;

function walk(dir, out = []) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (entry === ".build" || entry === "DerivedData" || entry.endsWith(".xcodeproj") || entry.endsWith(".xcresult")) continue;
    if (statSync(full).isDirectory()) walk(full, out);
    else if (entry.endsWith(".swift")) out.push(full);
  }
  return out;
}

// Comments become spaces and every string literal's contents become spaces (interpolations stay code), so that braces,
// parentheses and colons inside text never count. Newlines are kept so indices still map to lines.
function blank(source) {
  const out = source.split("");
  const space = (from, to) => { for (let k = from; k < to; k += 1) if (out[k] !== "\n") out[k] = " "; };
  let i = 0;
  const n = source.length;
  while (i < n) {
    const c = source[i];
    const c2 = source[i + 1];
    if (c === "/" && c2 === "/") { const end = source.indexOf("\n", i); const stop = end < 0 ? n : end; space(i, stop); i = stop; continue; }
    if (c === "/" && c2 === "*") {
      let depth = 1; let k = i + 2;
      while (k < n && depth > 0) {
        if (source[k] === "/" && source[k + 1] === "*") { depth += 1; k += 2; continue; }
        if (source[k] === "*" && source[k + 1] === "/") { depth -= 1; k += 2; continue; }
        k += 1;
      }
      space(i, k); i = k; continue;
    }
    if (c === "#" || c === '"') {
      let hashes = 0;
      while (source[i + hashes] === "#") hashes += 1;
      if (source[i + hashes] !== '"') { i += 1; continue; }
      const closingHashes = "#".repeat(hashes);
      const multi = source.startsWith('"""', i + hashes);
      const open = i + hashes + (multi ? 3 : 1);
      const closer = (multi ? '"""' : '"') + closingHashes;
      let k = open;
      let stringStart = open; // the run of literal text being blanked
      while (k < n) {
        if (source[k] === "\\") {
          const interp = hashes === 0 ? source[k + 1] === "(" : source.startsWith(closingHashes + "(", k + 1);
          if (interp) {
            space(stringStart, k);
            let depth = 0; let m = k + 1 + hashes; // at the "("
            while (m < n) { // the interpolation is code, possibly holding strings of its own — blank those recursively
              if (source[m] === "(") depth += 1;
              else if (source[m] === ")") { depth -= 1; if (depth === 0) break; }
              else if (source[m] === '"' || (source[m] === "#" && /^#+"/.test(source.slice(m, m + 8)))) {
                const innerEnd = endOfLiteral(source, m);
                const inner = blank(source.slice(m, innerEnd));
                for (let q = m; q < innerEnd; q += 1) out[q] = inner[q - m];
                m = innerEnd; continue;
              }
              m += 1;
            }
            k = m + 1; stringStart = k; continue;
          }
          k += 2; continue;
        }
        if (source.startsWith(closer, k)) break;
        k += 1;
      }
      space(stringStart, k);
      i = k + closer.length; continue;
    }
    i += 1;
  }
  return out.join("");
}

// Where the string literal starting at `at` (its leading #s or quote) ends — the index after its closer
function endOfLiteral(source, at) {
  let hashes = 0;
  while (source[at + hashes] === "#") hashes += 1;
  const closingHashes = "#".repeat(hashes);
  const multi = source.startsWith('"""', at + hashes);
  const closer = (multi ? '"""' : '"') + closingHashes;
  let k = at + hashes + (multi ? 3 : 1);
  while (k < source.length) {
    if (source[k] === "\\") {
      if (hashes === 0 && source[k + 1] === "(") { let depth = 0; let m = k + 1; while (m < source.length) { if (source[m] === "(") depth += 1; else if (source[m] === ")") { depth -= 1; if (depth === 0) break; } m += 1; } k = m + 1; continue; }
      k += 2; continue;
    }
    if (source.startsWith(closer, k)) return k + closer.length;
    k += 1;
  }
  return source.length;
}

const OPEN = { "(": ")", "[": "]", "{": "}" };
// The index of the bracket closing the one at `at`
function matching(code, at) {
  const close = OPEN[code[at]];
  let depth = 0;
  for (let k = at; k < code.length; k += 1) {
    const c = code[k];
    if (c === "(" || c === "[" || c === "{") depth += 1;
    else if (c === ")" || c === "]" || c === "}") { depth -= 1; if (depth === 0) return c === close ? k : k; }
  }
  return code.length - 1;
}

// Split `text` at top-level commas: (), [], {} and <> nest; "->" is not a bracket
function splitTop(text) {
  const parts = []; let depth = 0; let start = 0;
  for (let k = 0; k < text.length; k += 1) {
    const c = text[k];
    if (c === "-" && text[k + 1] === ">") { k += 1; continue; }
    if (c === "(" || c === "[" || c === "{" || c === "<") depth += 1;
    else if (c === ")" || c === "]" || c === "}" || c === ">") depth = Math.max(0, depth - 1);
    else if (c === "," && depth === 0) { parts.push(text.slice(start, k)); start = k + 1; }
  }
  parts.push(text.slice(start));
  return parts.map((part) => part.trim()).filter((part) => part.length > 0);
}

// A parameter list's labels: { label (null for `_`), required, closure, variadic }
function parseParams(text) {
  return splitTop(text).map((raw) => {
    let part = raw.replace(/^(?:@\w+(?:\([^)]*\))?\s+|inout\s+|borrowing\s+|consuming\s+|isolated\s+|_const\s+)+/, "");
    const head = part.match(/^([A-Za-z_]\w*|_)(?:\s+([A-Za-z_]\w*|_))?\s*:/);
    if (!head) return null;
    const label = head[1] === "_" ? null : head[1];
    const rest = part.slice(head[0].length);
    let depth = 0; let eq = -1;
    for (let k = 0; k < rest.length; k += 1) {
      const c = rest[k];
      if (c === "(" || c === "[" || c === "{" || c === "<") depth += 1;
      else if (c === ")" || c === "]" || c === "}" || c === ">") depth = Math.max(0, depth - 1);
      else if (c === "=" && depth === 0 && rest[k + 1] !== "=" && rest[k - 1] !== "=" && rest[k - 1] !== "!" && rest[k - 1] !== "<" && rest[k - 1] !== ">") { eq = k; break; }
    }
    const type = (eq < 0 ? rest : rest.slice(0, eq)).trim();
    return { label, required: eq < 0, closure: type.includes("->") || /^@escaping|@ViewBuilder|@autoclosure/.test(raw.trim()), variadic: type.endsWith("...") };
  }).filter(Boolean);
}

// Call-site argument labels (null = unlabeled)
function parseArgs(text) {
  return splitTop(text).map((arg) => { const m = arg.match(/^([A-Za-z_]\w*)\s*:(?!:)/); return m ? m[1] : null; });
}

function matches(params, args, hasTrailing) {
  let a = 0;
  for (const param of params) {
    if (a < args.length && args[a] === param.label) {
      a += 1;
      if (param.variadic) while (a < args.length && args[a] === param.label) a += 1;
      continue;
    }
    if (!param.required || param.variadic || (param.closure && hasTrailing)) continue;
    return false;
  }
  return a === args.length;
}

// Nested `{...}` blocks collapse to `{}` so a type body can be read one declaration at a time (no line number is ever
// taken from the flattened text)
function flatten(body) {
  let out = ""; let depth = 0;
  for (const c of body) {
    if (c === "{") { depth += 1; if (depth === 1) out += "{"; continue; }
    if (c === "}") { depth -= 1; if (depth === 0) out += "}"; continue; }
    if (depth === 0) out += c;
  }
  return out;
}

// One statement per entry: lines join while parentheses, brackets or a generic list are open ("<" counts only after an
// identifier, so `..<` and comparisons never glue lines together; "->" is not a closer)
function statements(flat) {
  const out = []; let current = ""; let depth = 0;
  for (const line of flat.replaceAll(";", "\n").split("\n")) { // `let a: Int; let b: Int` on one line is two declarations
    current += (current ? "\n" : "") + line;
    for (let k = 0; k < line.length; k += 1) {
      const c = line[k];
      if (c === "(" || c === "[" || (c === "<" && /\w/.test(line[k - 1] ?? ""))) depth += 1;
      else if (c === ")" || c === "]" || (c === ">" && line[k - 1] !== "-")) depth = Math.max(0, depth - 1);
    }
    if (depth === 0) { out.push(current); current = ""; }
  }
  if (current) out.push(current);
  return out;
}

const mainActorTypes = new Set(); // types declared @MainActor: their mutable statics and properties are unreachable from a nonisolated context
const types = new Map(); // simple name → { kinds, members:Set, inits:[{params, inBody}], funcs:Map name→[params], memberwise:[params|null], hasBodyInit, rawType, privateUndefaulted, declaredAt }
function typeEntry(name) {
  if (!types.has(name)) types.set(name, { kinds: new Set(), members: new Set(["self", "Type", "init"]), inits: [], funcs: new Map(), memberwise: [], hasBodyInit: false, declaredAt: [] });
  return types.get(name);
}

const files = walk(iosDir).map((file) => { const source = readFileSync(file, "utf8"); return { file, source, code: blank(source) }; });
const DECL = /\b(struct|class|enum|actor|extension|protocol)\s+([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)/g;

// Every declaration in a file with its body range; a type declared inside another is keyed `Outer.Inner` — its bare name is
// not what an unqualified reference at file scope resolves to (the module's nested `State` never hides SwiftUI's)
function declarations(code) {
  const out = [];
  for (const hit of code.matchAll(DECL)) {
    const [, kind, name] = hit;
    if (kind === "class" && /^(func|var|let)$/.test(name)) continue;
    let k = hit.index + hit[0].length; let angle = 0;
    while (k < code.length && (angle > 0 || code[k] !== "{")) { if (code[k] === "<") angle += 1; else if (code[k] === ">") angle -= 1; else if (code[k] === "\n" && angle === 0 && /^\s*(?:@|\b(?:struct|class|enum|actor|extension|protocol|func|var|let|import)\b)/.test(code.slice(k + 1, k + 60))) break; k += 1; }
    if (code[k] !== "{") continue;
    out.push({ kind, name, index: hit.index, open: k, end: matching(code, k) });
  }
  for (const decl of out) {
    const parent = out.filter((other) => other !== decl && other.kind !== "extension" && other.open < decl.index && other.end > decl.index).sort((a, b) => b.open - a.open)[0];
    decl.parent = parent;
    decl.key = parent ? `${parent.key ?? parent.name}.${decl.name}` : decl.name;
  }
  return out;
}

// Pass 1 — declarations and their members
for (const { file, code } of files) {
  const decls = declarations(code);
  for (const decl of decls) {
    const { kind, name, key, open: k, end } = decl;
    if (kind === "protocol") continue;
    const header = code.slice(decl.index, k);
    const entry = typeEntry(key);
    entry.kinds.add(kind);
    if (/@MainActor\b/.test(code.slice(Math.max(0, decl.index - 160), decl.index))) mainActorTypes.add(name);
    if (decl.parent) typeEntry(decl.parent.key).members.add(name);
    if (kind !== "extension") entry.declaredAt.push(`${relative(repoRoot, file).replaceAll("\\", "/")}:${lineOf(code, decl.index)}`);
    const rawType = kind === "enum" ? header.match(/:\s*(String|Int|Double|UInt8|Int64|Character)\b/) : null;
    if (rawType) { entry.rawType = rawType[1]; entry.inits.push({ params: [{ label: "rawValue", required: true, closure: false, variadic: false }], inBody: false }); entry.members.add("allCases"); }
    if (kind === "enum") entry.members.add("allCases");
    if (/\b(Codable|Decodable|Encodable)\b/.test(header)) entry.members.add("CodingKeys");
    const stored = [];
    let privateUndefaulted = false;
    for (const statement of statements(flatten(code.slice(k + 1, end)))) {
      const s = statement.trim();
      if (!s) continue;
      const caseMatch = s.match(/^(?:indirect\s+)?case\s+(.+)$/s);
      if (caseMatch && kind !== "extension") { for (const item of splitTop(caseMatch[1])) { const m = item.match(/^([A-Za-z_]\w*)/); if (m) entry.members.add(m[1]); } continue; }
      const initMatch = s.match(/^((?:@\w+(?:\([^)]*\))?\s+|[a-z]+(?:\(set\))?\s+)*)init\s*[?!]?\s*(?:<[^{]*?>)?\s*\(/);
      if (initMatch) {
        const open = s.indexOf("(", initMatch[0].length - 1);
        const close = matching(s, open);
        entry.inits.push({ params: parseParams(s.slice(open + 1, close)), inBody: kind !== "extension" });
        if (kind !== "extension") entry.hasBodyInit = true;
        continue;
      }
      const funcMatch = s.match(/^((?:@\w+(?:\([^)]*\))?\s+|[a-z]+(?:\(set\))?\s+)*)func\s+([A-Za-z_]\w*)\s*(?:<[^{(]*?>)?\s*\(/);
      if (funcMatch) {
        const open = s.indexOf("(", funcMatch[0].length - 1);
        const close = matching(s, open);
        if (!entry.funcs.has(funcMatch[2])) entry.funcs.set(funcMatch[2], []);
        entry.funcs.get(funcMatch[2]).push(parseParams(s.slice(open + 1, close)));
        entry.members.add(funcMatch[2]);
        continue;
      }
      const propMatch = s.match(/^((?:@\w+(?:\([^)]*\))?\s+|[a-z]+(?:\(set\))?\s+)*)(let|var)\s+([A-Za-z_]\w*)\s*(?::\s*([^=\n]*?))?\s*(?:(=)\s*([\s\S]*?))?\s*(\{\})?\s*$/);
      if (propMatch) {
        const [, prefix, keyword, propName, type, eq, , block] = propMatch;
        entry.members.add(propName);
        const words = prefix.trim().split(/\s+/).filter(Boolean);
        const wrapper = words.find((w) => w.startsWith("@"))?.replace(/^@/, "").replace(/\(.*$/, "");
        const isStatic = words.some((w) => w === "static" || w === "class");
        const isPrivate = words.some((w) => w.startsWith("private") || w.startsWith("fileprivate"));
        const computed = block !== undefined && eq === undefined;
        if (kind !== "struct" || isStatic || computed) continue;
        const hasDefault = eq !== undefined || (wrapper !== undefined && !WRAPPERS_REQUIRED.has(wrapper)) || (type !== undefined && keyword === "var" && /[?]\s*$/.test(type.trim()));
        if (keyword === "let" && eq !== undefined) continue; // a `let` with a value is not a memberwise parameter
        if (isPrivate && hasDefault) continue;   // omitted from the memberwise initializer
        if (isPrivate) privateUndefaulted = true; // the memberwise initializer itself is private — not callable from another file
        stored.push({ label: propName, required: !hasDefault, closure: (type ?? "").includes("->"), variadic: false });
        continue;
      }
      const aliasMatch = s.match(/^(?:[a-z]+\s+)*typealias\s+([A-Za-z_]\w*)/);
      if (aliasMatch) entry.members.add(aliasMatch[1]);
    }
    if (kind === "struct") entry.memberwise.push(privateUndefaulted ? null : stored);
  }
}
function lineOf(code, index) { let line = 1; for (let k = 0; k < index; k += 1) if (code[k] === "\n") line += 1; return line; }

// Pass 2 — references
const findings = [];
const REF = /(^|[^.\w\\$@])([A-Z]\w*)(\s*<[^()<>{}]*>)?\s*(\(|\.\s*([A-Za-z_]\w*)\s*(\()?)/gm;
const TYPED = /:\s*(\[)?\s*([A-Z]\w*)\s*(\])?\s*=\s*(\[)?/g;
for (const { file, code } of files) {
  const where = (index) => `${relative(repoRoot, file).replaceAll("\\", "/")}:${lineOf(code, index)}`;
  for (const hit of code.matchAll(REF)) {
    const [whole, lead, name, , tail, member, memberCall] = hit;
    const entry = types.get(name); // top-level declarations only: a nested type is keyed Outer.Inner and reached through its parent
    if (!entry || entry.declaredAt.length === 0 || MODULE_NAMES.has(name)) continue; // extension-only names are Apple's types
    const at = hit.index + lead.length;
    const before = code.slice(Math.max(0, at - 12), at);
    if (/\b(func|struct|class|enum|actor|extension|protocol|typealias|case|import)\s+$/.test(before)) continue;
    const open = hit.index + whole.length - 1; // the "(" the match ends on (init call or member call)
    if (tail === "(") { checkInit(entry, name, code, open, where(at)); continue; }
    if (!entry.members.has(member)) {
      if (/^(init|self|Type|Protocol)$/.test(member)) continue;
      findings.push(`${where(at)}: ${name}.${member} — ${name} (${entry.declaredAt.join(", ") || "extension only"}) declares no member "${member}"`);
      continue;
    }
    // 4. `Type.shared.method(...)` — the regex ends at `.shared`; look one member further and label-check the instance call
    //    exactly the way a static call is checked. Only a direct `.shared.name(` is examined: a property chain after
    //    `.shared` (`.shared.currentUser?.id`, `.shared.context.insert(`) is left alone, so precision holds.
    if (memberCall !== "(" && member === "shared") {
      const via = code.slice(hit.index + whole.length).match(/^\s*\.\s*([A-Za-z_]\w*)\s*\(/);
      if (via) {
        const method = via[1];
        if (!entry.members.has(method)) {
          findings.push(`${where(at)}: ${name}.shared.${method} — ${name} (${entry.declaredAt.join(", ")}) declares no member "${method}"`);
        } else {
          const candidates = entry.funcs.get(method);
          if (candidates && candidates.length > 0) {
            const viaOpen = hit.index + whole.length + via[0].length - 1;
            const close = matching(code, viaOpen);
            const args = parseArgs(code.slice(viaOpen + 1, close));
            const hasTrailing = /^\s*\{/.test(code.slice(close + 1, close + 40));
            if (!candidates.some((params) => matches(params, args, hasTrailing))) findings.push(`${where(at)}: ${name}.shared.${method}(${describe(args)}) matches none of ${candidates.map((p) => `(${describe(p.map((q) => q.label))})`).join(" / ")}`);
          }
        }
      }
      continue;
    }
    if (memberCall !== "(") continue;
    if (member === "init") { checkInit(entry, name, code, open, where(at)); continue; }
    const nested = types.get(`${name}.${member}`) ?? (types.get(member)?.declaredAt.length ? types.get(member) : undefined);
    if (nested && !entry.funcs.has(member)) { checkInit(nested, `${name}.${member}`, code, open, where(at)); continue; }
    const candidates = entry.funcs.get(member);
    if (!candidates || candidates.length === 0) continue; // a case payload or a stored closure — not label-checked
    const close = matching(code, open);
    const args = parseArgs(code.slice(open + 1, close));
    const hasTrailing = /^\s*\{/.test(code.slice(close + 1, close + 40));
    if (candidates.some((params) => matches(params, args, hasTrailing))) continue;
    if (args.length === 1 && args[0] === null) continue; // an unapplied instance method reference: Type.method(instance)
    findings.push(`${where(at)}: ${name}.${member}(${describe(args)}) matches none of ${candidates.map((p) => `(${describe(p.map((q) => q.label))})`).join(" / ")}`);
  }
  // `let x: Kind = .a` and `let xs: [Kind] = [.a, .b]` — the one place an implicit-member case name has a type on the same line
  for (const hit of code.matchAll(TYPED)) {
    const [whole, , name, , literalOpen] = hit;
    const entry = types.get(name);
    if (!entry || entry.declaredAt.length === 0 || !entry.kinds.has("enum")) continue;
    const start = hit.index + whole.length;
    const elements = literalOpen ? splitTop(code.slice(start, matching(code, start - 1))) : [code.slice(start, start + 80)];
    for (const element of elements) {
      const m = element.match(/^\s*\.([A-Za-z_]\w*)/);
      if (m && !entry.members.has(m[1])) findings.push(`${where(hit.index)}: .${m[1]} — ${name} (${entry.declaredAt.join(", ")}) declares no case "${m[1]}"`);
    }
  }
}

function describe(labels) { return labels.map((label) => `${label ?? "_"}:`).join(""); }

function checkInit(entry, name, code, open, at) {
  const candidates = entry.inits.map((init) => init.params);
  if (!entry.hasBodyInit) for (const memberwise of entry.memberwise) if (memberwise) candidates.push(memberwise);
  if (candidates.length === 0) return; // a class with only the implicit init, or a private memberwise init: nothing to compare against
  const close = matching(code, open);
  const args = parseArgs(code.slice(open + 1, close));
  const hasTrailing = /^\s*\{/.test(code.slice(close + 1, close + 40));
  if (candidates.some((params) => matches(params, args, hasTrailing))) return;
  const hint = SWIFTUI_NAMES.has(name.split(".").pop()) ? ` — the module's ${name} shadows SwiftUI's; a call meant for SwiftUI's needs the SwiftUI. prefix` : "";
  findings.push(`${at}: ${name}(${describe(args)}) matches no initializer of ${name} (${entry.declaredAt.join(", ")}): ${candidates.map((p) => `(${describe(p.map((q) => q.label))})`).join(" / ")}${hint}`);
}

// Pass 3 — a parameter's DEFAULT VALUE is evaluated in a nonisolated context, even inside a @MainActor type, so reading a
// property through a main-actor singleton there is a hard compile error ("main actor-isolated property … can not be
// referenced from a nonisolated context"). `Type = .shared` is fine (a static let is only a warning today); it is the
// `.shared.property` read that fails. Run 34405436792 died on exactly one of these after AuthStore became @MainActor.
const SIGNATURE = /\b(?:init|func\s+[A-Za-z_]\w*)\s*(?:<[^{()<>]*>)?\s*\(/g;
const ISOLATED_READ = /\b([A-Z]\w*)\s*\.\s*shared\s*\.\s*[A-Za-z_]/;
for (const { file, code } of files) {
  for (const hit of code.matchAll(SIGNATURE)) {
    const open = hit.index + hit[0].length - 1;
    for (const part of splitTop(code.slice(open + 1, matching(code, open)))) {
      const value = defaultValueOf(part);
      const read = value === null ? null : value.match(ISOLATED_READ);
      if (read && mainActorTypes.has(read[1])) {
        findings.push(`${relative(repoRoot, file).replaceAll("\\", "/")}:${lineOf(code, hit.index)}: a parameter default reads ${read[1]}.shared.… — ${read[1]} is @MainActor and a default value is evaluated in a nonisolated context; pass it at the call site or read it in the body`);
      }
    }
  }
}

// The text after a parameter's top-level `=`, or null when it has no default
function defaultValueOf(part) {
  let depth = 0;
  for (let k = 0; k < part.length; k += 1) {
    const c = part[k];
    if (c === "(" || c === "[" || c === "{" || c === "<") depth += 1;
    else if (c === ")" || c === "]" || c === "}" || c === ">") depth = Math.max(0, depth - 1);
    else if (c === "=" && depth === 0 && part[k + 1] !== "=" && !"=!<>".includes(part[k - 1] ?? "")) return part.slice(k + 1).trim();
  }
  return null;
}

findings.sort();
if (findings.length > 0) {
  console.error(`swift-xref: ${findings.length} finding(s)\n${findings.join("\n")}`);
  process.exit(1);
}
console.log(`swift-xref: ${files.length} Swift files, ${types.size} types, clean`);
