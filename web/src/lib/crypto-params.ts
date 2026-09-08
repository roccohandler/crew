// The one file that names cryptographic parameters (Part IV: crypto.scrypt for passwords; opaque refresh tokens;
// single-use reset tokens). Not spec numbers, so not in spec-constants.json; exempt from the magic-number rule by name.
export const CryptoParams = {
  scryptSaltBytes: 16,
  scryptKeyLength: 64,
  scryptCost: 16384, // N
  scryptBlockSize: 8, // r
  scryptParallelization: 1, // p
  scryptMaxMemoryBytes: 64 * 1024 * 1024,
  opaqueTokenBytes: 32, // refresh + reset tokens, base64url
  inviteTokenBytes: 12, // crew invite links — short enough for iMessage, unguessable
  photoKeyBytes: 16,
  jwtSecretMinBytes: 32,
} as const;
