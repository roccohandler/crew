"use client";
// SPEC: 1C (authenticate once per device) · E18 (standard resets) · 6.6 (verb-first CTAs). Web twin of ios LoginScreen.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { isApiClientError, login, requestPasswordReset } from "@/lib/api-client";

export function LoginForm({ appleHref }: { appleHref: string }) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [resetSent, setResetSent] = useState(false);
  const [busy, setBusy] = useState(false);

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await login({ email, password });
      router.push("/home");
    } catch (caught) {
      setError(isApiClientError(caught) ? caught.message : "Something went wrong. Try again.");
      setBusy(false);
    }
  };

  const forgot = async () => {
    if (email.length === 0) { setError("Type your email first, then tap forgot."); return; }
    await requestPasswordReset(email).catch(() => undefined);
    setResetSent(true);
  };

  return (
    <form className="stack" onSubmit={submit}>
      <h1>Welcome back</h1>
      <a className="button button--primary" href={appleHref} rel="nofollow">Sign in with Apple</a>
      <label className="field"><span>Email</span><input type="email" autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} required /></label>
      <label className="field"><span>Password</span><input type="password" autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} required /></label>
      {error ? <p className="danger" role="alert">{error}</p> : null}
      <button type="submit" className="button button--primary" disabled={busy}>Log in</button>
      <button type="button" className="button button--text" onClick={forgot}>{resetSent ? "Check your email for the reset link" : "Forgot your password?"}</button>
    </form>
  );
}
