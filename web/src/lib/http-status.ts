// The one file that names HTTP status codes (docs/api.md conventions). Not spec numbers, so not in
// spec-constants.json; exempt from the magic-number rule by name in eslint.config.mjs.
export const HttpStatus = {
  ok: 200,
  created: 201,
  accepted: 202,
  noContent: 204,
  badRequest: 400,
  unauthorized: 401,
  forbidden: 403,
  notFound: 404,
  conflict: 409,
  payloadTooLarge: 413,
  tooManyRequests: 429,
  internal: 500,
} as const;
