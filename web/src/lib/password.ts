// SPEC: Part IV — password hashing uses Node's built-in crypto.scrypt, no extra dependency. Stored as
// "scrypt$<salt b64url>$<hash b64url>" so parameters can change later without a second field.
import { randomBytes, scrypt, timingSafeEqual } from "node:crypto";
import { CryptoParams } from "@/lib/crypto-params";

const options = { N: CryptoParams.scryptCost, r: CryptoParams.scryptBlockSize, p: CryptoParams.scryptParallelization, maxmem: CryptoParams.scryptMaxMemoryBytes };

function derive(password: string, salt: Buffer, length: number): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    scrypt(password, salt, length, options, (error, key) => (error ? reject(error) : resolve(key)));
  });
}

export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(CryptoParams.scryptSaltBytes);
  const derived = await derive(password, salt, CryptoParams.scryptKeyLength);
  return `scrypt$${salt.toString("base64url")}$${derived.toString("base64url")}`;
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const [scheme, saltText, hashText] = stored.split("$");
  if (scheme !== "scrypt" || !saltText || !hashText) return false;
  const expected = Buffer.from(hashText, "base64url");
  const derived = await derive(password, Buffer.from(saltText, "base64url"), expected.length);
  return derived.length === expected.length && timingSafeEqual(derived, expected);
}
