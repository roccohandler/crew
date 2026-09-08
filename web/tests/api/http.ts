// Test helpers: build Requests the way the clients do and call route handlers directly (real handlers, real
// database — C4). No HTTP server is needed; Next route handlers are plain functions of Request.
export const BASE = "http://localhost:3000/api/v1";

export interface CallOptions {
  body?: unknown;
  rawBody?: string;
  token?: string;
  cookie?: string;
  ios?: boolean;
  ip?: string;
  headers?: Record<string, string>;
}

export function request(method: string, path: string, options: CallOptions = {}): Request {
  const headers = new Headers(options.headers ?? {});
  if (options.body !== undefined || options.rawBody !== undefined) headers.set("content-type", "application/json");
  if (options.token) headers.set("authorization", `Bearer ${options.token}`);
  if (options.cookie) headers.set("cookie", options.cookie);
  if (options.ios !== false) headers.set("x-crew-client", "ios");
  if (options.ip) headers.set("x-forwarded-for", options.ip);
  const body = options.rawBody ?? (options.body === undefined ? undefined : JSON.stringify(options.body));
  return new Request(`${BASE}${path}`, { method, headers, body });
}

export async function readJson<T = Record<string, unknown>>(response: Response): Promise<T> {
  return (await response.json()) as T;
}

export function cookiesFrom(response: Response): string {
  return response.headers
    .getSetCookie()
    .map((line) => line.split(";")[0] ?? "")
    .join("; ");
}
