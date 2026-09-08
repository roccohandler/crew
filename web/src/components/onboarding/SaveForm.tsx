"use client";
// SPEC: S05 "Save your plan" — the Sign in with Apple button primary (black), email beneath with autocomplete so the password
// manager fills it; validation on field-exit, one inline line; E9 (terms line + birth year). Web twin of ios SaveAuthScreen.
import { useState } from "react";
import { isApiClientError, register } from "@/lib/api-client";
import { SpecConstants } from "@/generated/spec-constants";

type Fields = { displayName: string; email: string; password: string; birthYear: string };
type FieldName = keyof Fields;

function validateField(name: FieldName, value: string): string {
  if (name === "displayName" && value.trim().length === 0) return "Add a name your crew will recognize.";
  if (name === "email" && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value)) return "That doesn't look like an email.";
  if (name === "password" && value.length < SpecConstants.passwordMinChars) return `At least ${SpecConstants.passwordMinChars} characters.`;
  if (name === "birthYear" && !/^\d{4}$/.test(value)) return "Four digits, like 1994.";
  return "";
}

function Field({ name, label, type, autoComplete, value, error, onChange, onExit }: { name: FieldName; label: string; type: string; autoComplete: string; value: string; error: string; onChange: (value: string) => void; onExit: () => void }) {
  return (
    <label className={error ? "field field--error" : "field"}>
      <span>{label}</span>
      <input name={name} type={type} autoComplete={autoComplete} value={value} onChange={(event) => onChange(event.target.value)} onBlur={onExit} required />
      {error ? <span className="danger whisper" role="alert">{error}</span> : null}
    </label>
  );
}

export function SaveForm({ appleHref, onSaved }: { appleHref: string; onSaved: () => Promise<void> }) {
  const [fields, setFields] = useState<Fields>({ displayName: "", email: "", password: "", birthYear: "" });
  const [errors, setErrors] = useState<Record<FieldName, string>>({ displayName: "", email: "", password: "", birthYear: "" });
  const [serverError, setServerError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const names: FieldName[] = ["displayName", "email", "password", "birthYear"];

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    const found = { displayName: validateField("displayName", fields.displayName), email: validateField("email", fields.email), password: validateField("password", fields.password), birthYear: validateField("birthYear", fields.birthYear) };
    setErrors(found);
    if (names.some((name) => found[name].length > 0)) return;
    setSaving(true);
    setServerError(null);
    try {
      await register({ email: fields.email, password: fields.password, displayName: fields.displayName.trim(), timezone: Intl.DateTimeFormat().resolvedOptions().timeZone, eulaAccepted: true, birthYear: Number(fields.birthYear) });
      await onSaved();
    } catch (error) {
      setServerError(isApiClientError(error) ? error.message : "Something went wrong. Try again.");
      setSaving(false);
    }
  };

  const labels: Record<FieldName, [string, string, string]> = { displayName: ["Name", "text", "name"], email: ["Email", "email", "username"], password: ["Password", "password", "new-password"], birthYear: ["Birth year", "text", "bday-year"] };
  return (
    <form className="stack" onSubmit={submit} noValidate>
      <h1>Save your plan</h1>
      <p className="muted">The plan is yours. An account is how you keep it.</p>
      <a className="button button--primary" href={appleHref} rel="nofollow">Sign in with Apple</a>
      <p className="whisper">or with email</p>
      {names.map((name) => <Field key={name} name={name} label={labels[name][0]} type={labels[name][1]} autoComplete={labels[name][2]} value={fields[name]} error={errors[name]} onChange={(value) => setFields({ ...fields, [name]: value })} onExit={() => setErrors({ ...errors, [name]: validateField(name, fields[name]) })} />)}
      <p className="whisper">By saving you agree to the terms. Crew is for people {SpecConstants.minimumAgeYears} and up.</p>
      {serverError ? <p className="danger" role="alert">{serverError}</p> : null}
      <button type="submit" className="button button--primary" disabled={saving}>{saving ? "Saving…" : "Save your plan"}</button>
    </form>
  );
}
