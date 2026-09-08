// Test substitute for Apple's key server: an RSA key pair and a tiny local JWKS endpoint, so
// verifyAppleIdentityToken runs the real jose verification path without Apple (continuous-build rule 3b).
import { createServer, type Server } from "node:http";
import { SignJWT, exportJWK, generateKeyPair } from "jose";

export interface FakeApple {
  url: string;
  sign: (claims: Record<string, unknown>, options?: { audience?: string; issuer?: string }) => Promise<string>;
  stop: () => Promise<void>;
}

export async function startFakeApple(audience: string): Promise<FakeApple> {
  const { privateKey, publicKey } = await generateKeyPair("RS256");
  const jwk = { ...(await exportJWK(publicKey)), kid: "test-key", alg: "RS256", use: "sig" };
  const server: Server = createServer((_req, res) => {
    res.setHeader("content-type", "application/json");
    res.end(JSON.stringify({ keys: [jwk] }));
  });
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  const port = typeof address === "object" && address !== null ? address.port : 0;
  return {
    url: `http://127.0.0.1:${port}/auth/keys`,
    sign: (claims, options = {}) =>
      new SignJWT(claims)
        .setProtectedHeader({ alg: "RS256", kid: "test-key" })
        .setIssuer(options.issuer ?? "https://appleid.apple.com")
        .setAudience(options.audience ?? audience)
        .setIssuedAt()
        .setExpirationTime("10m")
        .sign(privateKey),
    stop: () => new Promise<void>((resolve) => server.close(() => resolve())),
  };
}
