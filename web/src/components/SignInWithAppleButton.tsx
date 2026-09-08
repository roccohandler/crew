// SPEC: 1C (the native Sign in with Apple button is black — it IS the ink system — and sits primary) · Part III law ①
// (ink acts) · T012 (web button). The web flow is Apple's OAuth redirect; the callback route sets the cookies.
import { appleAuthorizeUrl } from "@/lib/apple-auth";

interface SignInWithAppleButtonProps {
  timezone: string;
  eulaAccepted: boolean;
  birthYear?: number;
  next?: string;
}

export function SignInWithAppleButton({ timezone, eulaAccepted, birthYear, next }: SignInWithAppleButtonProps) {
  const state = new URLSearchParams({ tz: timezone, eula: eulaAccepted ? "1" : "0", next: next ?? "/home" });
  if (birthYear !== undefined) state.set("by", String(birthYear));
  return (
    <a className="button button--primary" href={appleAuthorizeUrl(state.toString())} rel="nofollow">
      Sign in with Apple
    </a>
  );
}
