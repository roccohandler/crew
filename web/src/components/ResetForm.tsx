"use client";
// SPEC: Part IV — the reset link works once and expires; a dead link says so and offers a fresh one (6.1: never a dead end).
import Link from "next/link";
import { useState } from "react";
import { confirmPasswordReset, isApiClientError } from "@/lib/api-client";
import { SpecConstants } from "@/generated/spec-constants";

export function ResetForm({ token }: { token: string }) {
  const [password, setPassword] = useState("");
  const [state, setState] = useState<"idle" | "done" | "dead">("idle");
  const [error, setError] = useState<string | null>(null);

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (password.length < SpecConstants.passwordMinChars) { setError(`At least ${SpecConstants.passwordMinChars} characters.`); return; }
    try {
      await confirmPasswordReset(token, password);
      setState("done");
    } catch (caught) {
      if (isApiClientError(caught) && caught.code === "resetTokenInvalid") setState("dead");
      else setError("Something went wrong. Try again.");
    }
  };

  if (state === "done") return <div className="stack"><h1>New password saved</h1><Link className="button button--primary" href="/login">Log in</Link></div>;
  if (state === "dead") return <div className="stack"><h1>{"That link's expired"}</h1><p className="muted">Reset links work once and last {SpecConstants.passwordResetTokenExpiryMinutes} minutes.</p><Link className="button button--primary" href="/login">Get a fresh one</Link></div>;
  return (
    <form className="stack" onSubmit={submit}>
      <h1>Choose a new password</h1>
      <label className="field"><span>New password</span><input type="password" autoComplete="new-password" value={password} onChange={(event) => setPassword(event.target.value)} required /></label>
      {error ? <p className="danger" role="alert">{error}</p> : null}
      <button type="submit" className="button button--primary">Save password</button>
    </form>
  );
}
