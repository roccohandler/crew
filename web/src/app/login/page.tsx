// SPEC: S02 tertiary "Log in" — the login screen is a failure state, not a feature (1C); email + password, Sign in with Apple,
// forgot-password (E18). Web twin of ios LoginScreen. W5 (2026-09-17): a failed Apple web sign-in lands here with ?apple=failed and
// reads one line (6.1: what happened + what to do); the Apple button starts at the server's start route (state/nonce bound).
import { LoginForm } from "@/components/LoginForm";
import { appleStartUrl } from "@/lib/apple-auth";

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ apple?: string }> }) {
  const { apple } = await searchParams;
  return (
    <main className="app-column">
      <LoginForm appleHref={appleStartUrl({ eula: false, next: "/home" })} appleFailed={apple === "failed"} />
    </main>
  );
}
