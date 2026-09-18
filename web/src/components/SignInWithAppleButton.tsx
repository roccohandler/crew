// SPEC: 1C (the native Sign in with Apple button is black — it IS the ink system — and sits primary) · Part III law ①
// (ink acts) · T012 (web button). The web flow is Apple's OAuth redirect; W5 (2026-09-17): it starts at the server's start route,
// which binds the attempt (signed state · nonce cookie · id_token nonce) before sending the browser to Apple.
import { appleStartUrl } from "@/lib/apple-auth";

interface SignInWithAppleButtonProps {
  timezone: string;
  eulaAccepted: boolean;
  birthYear?: number;
  next?: string;
}

export function SignInWithAppleButton({ timezone, eulaAccepted, birthYear, next }: SignInWithAppleButtonProps) {
  return (
    <a className="button button--primary" href={appleStartUrl({ eula: eulaAccepted, next: next ?? "/home", tz: timezone, by: birthYear })} rel="nofollow">
      Sign in with Apple
    </a>
  );
}
