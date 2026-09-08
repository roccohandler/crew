"use client";
// SPEC: W1 — joining via web ≤ 3 interactions post-auth: this is one.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { isApiClientError } from "@/lib/api-client";
import { joinCrew } from "@/lib/api-client-crew";

export function JoinButton({ token }: { token: string }) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const join = async () => {
    try {
      await joinCrew(token);
      router.push("/crew");
    } catch (caught) {
      setError(isApiClientError(caught) ? caught.message : "Couldn't join right now. Try again.");
    }
  };
  return (
    <div className="stack stack--tight">
      <button type="button" className="button button--primary" onClick={join}>Join the crew</button>
      {error ? <p className="danger" role="alert">{error}</p> : null}
    </div>
  );
}
