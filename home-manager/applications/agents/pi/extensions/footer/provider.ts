import type { ProviderQuota } from "./state";
import { progressBar } from "./render";

export async function fetchAnthropicQuota(): Promise<ProviderQuota | null> {
  const token = process.env.ANTHROPIC_OAUTH_TOKEN;
  if (!token) return null;
  try {
    const response = await fetch("https://api.anthropic.com/api/oauth/usage", {
      headers: { Authorization: `Bearer ${token}`, "anthropic-beta": "oauth-2025-04-20" },
    });
    if (!response.ok) return null;
    const usage = (await response.json()) as {
      five_hour?: { utilization?: number; resets_at?: string };
      seven_day?: { utilization?: number };
    };
    const current = usage.five_hour?.utilization;
    const weekly = usage.seven_day?.utilization;
    if (typeof current !== "number" || typeof weekly !== "number") return null;
    const resetAt = usage.five_hour?.resets_at;
    const minutes = resetAt
      ? Math.max(0, Math.round((Date.parse(resetAt) - Date.now()) / 60_000))
      : 0;
    const duration = resetAt
      ? minutes >= 60
        ? `${Math.floor(minutes / 60)}h ${minutes % 60}m`
        : `${minutes}m`
      : "";
    return {
      label: "anthropic",
      percent: current,
      detail: `${duration}  Weekly: ${progressBar(weekly, 10)} ${weekly.toFixed(1)}%`,
    };
  } catch {
    return null;
  }
}

export function quotaFromHeaders(
  provider: string,
  headers: Record<string, string>,
): ProviderQuota | null {
  if (!provider.startsWith("azure")) return null;
  const limit = Number(headers["x-ratelimit-limit-tokens"]);
  const remaining = Number(headers["x-ratelimit-remaining-tokens"]);
  if (!Number.isFinite(limit) || limit <= 0 || !Number.isFinite(remaining)) return null;
  return { label: "azure", percent: ((limit - remaining) / limit) * 100 };
}
