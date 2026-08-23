function trimTrailingSlash(value: string): string {
  return value.replace(/\/+$/, "");
}

function serverApiBaseUrl(): string {
  const value = process.env.BPT_API_BASE_URL ?? process.env.NEXT_PUBLIC_BPT_API_BASE_URL;
  if (!value) {
    throw new Error("BPT_API_BASE_URL or NEXT_PUBLIC_BPT_API_BASE_URL is required at runtime.");
  }

  return trimTrailingSlash(value);
}

export async function recordWhatsAppLead(listingId: string): Promise<void> {
  const url = new URL("/api/app/lead", `${serverApiBaseUrl()}/`);
  url.searchParams.set("listingId", listingId);

  const response = await fetch(url, {
    method: "POST",
    cache: "no-store",
    headers: { Accept: "application/json" },
  });

  if (!response.ok) {
    throw new Error(`Lead create failed with HTTP ${response.status}.`);
  }
}
