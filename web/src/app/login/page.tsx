// SPEC: S02 tertiary "Log in" — the login screen is a failure state, not a feature (1C); email + password, Sign in with Apple,
// forgot-password (E18). Web twin of ios LoginScreen.
import { LoginForm } from "@/components/LoginForm";
import { appleAuthorizeUrl } from "@/lib/apple-auth";

export default function LoginPage() {
  return (
    <main className="app-column">
      <LoginForm appleHref={appleAuthorizeUrl(new URLSearchParams({ eula: "0", next: "/home" }).toString())} />
    </main>
  );
}
