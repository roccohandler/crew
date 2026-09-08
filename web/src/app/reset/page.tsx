// SPEC: Part IV password reset (single-use link, 30 min) — the page the email links to. T011/T036
import { ResetForm } from "@/components/ResetForm";

export default async function ResetPage({ searchParams }: { searchParams: Promise<{ token?: string }> }) {
  const { token } = await searchParams;
  return (
    <main className="app-column">
      <ResetForm token={token ?? ""} />
    </main>
  );
}
