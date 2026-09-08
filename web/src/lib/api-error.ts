// SPEC: C13 — errors are boring: one apiError(code, message, status) function, one error shape
// `{ error: { code, message } }` (docs/api.md conventions). Routes `throw apiError(...)` and end with
// `catch (error) { return errorResponse(error) }` — visible, no middleware chain (C6).
import { ZodError } from "zod";
import { HttpStatus } from "@/lib/http-status";

export interface ApiError {
  isApiError: true;
  code: string;
  message: string;
  status: number;
}

export function apiError(code: string, message: string, status: number): ApiError {
  return { isApiError: true, code, message, status };
}

export function isApiError(value: unknown): value is ApiError {
  return typeof value === "object" && value !== null && (value as ApiError).isApiError === true;
}

export function json(body: unknown, status: number = HttpStatus.ok, headers?: HeadersInit): Response {
  const response = Response.json(body, { status });
  new Headers(headers).forEach((value, key) => response.headers.append(key, value));
  return response;
}

export function errorResponse(error: unknown): Response {
  if (isApiError(error)) return Response.json({ error: { code: error.code, message: error.message } }, { status: error.status });
  if (error instanceof ZodError) {
    const first = error.issues[0];
    const where = first ? first.path.join(".") : "body";
    const message = first ? `${where || "body"}: ${first.message}` : "Invalid request body.";
    return Response.json({ error: { code: "validation", message } }, { status: HttpStatus.badRequest });
  }
  if (error instanceof SyntaxError) {
    return Response.json({ error: { code: "validation", message: "Body is not valid JSON." } }, { status: HttpStatus.badRequest });
  }
  console.error("unhandled route error", error);
  return Response.json({ error: { code: "internal", message: "Something went wrong on our side. Try again." } }, { status: HttpStatus.internal });
}

export const notFound = (what: string) => apiError("notFound", `${what} not found.`, HttpStatus.notFound);
export const forbidden = (why: string) => apiError("forbidden", why, HttpStatus.forbidden);
export const unauthorized = () => apiError("unauthorized", "Sign in to continue.", HttpStatus.unauthorized);
