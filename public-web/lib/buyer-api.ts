import type { PublicListing } from "./public-listings";

function apiBaseUrl(): string {
  return (
    process.env.NEXT_PUBLIC_BPT_API_BASE_URL ??
    process.env.NEXT_PUBLIC_BPT_AUTHORITY ??
    "http://127.0.0.1:5093"
  ).replace(/\/$/, "");
}

async function buyerRequest(path: string, accessToken: string, init?: RequestInit) {
  const headers = new Headers(init?.headers);
  headers.set("Authorization", `Bearer ${accessToken}`);
  const response = await fetch(`${apiBaseUrl()}${path}`, {
    ...init,
    headers,
    cache: "no-store",
  });

  if (response.status === 401) {
    throw new Error("Sua sessão expirou. Entre novamente para continuar.");
  }
  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`A API de favoritos respondeu ${response.status}${detail ? `: ${detail}` : "."}`);
  }
  return response;
}

export async function getMyFavorites(accessToken: string): Promise<PublicListing[]> {
  const response = await buyerRequest("/api/app/favorite/mine", accessToken);
  return (await response.json()) as PublicListing[];
}

export async function isFavorite(accessToken: string, listingId: string): Promise<boolean> {
  const response = await buyerRequest(
    `/api/app/favorite/is-favorite/${encodeURIComponent(listingId)}`,
    accessToken,
  );
  return (await response.json()) as boolean;
}

export async function addFavorite(accessToken: string, listingId: string): Promise<void> {
  await buyerRequest(`/api/app/favorite?listingId=${encodeURIComponent(listingId)}`, accessToken, {
    method: "POST",
  });
}

export async function removeFavorite(accessToken: string, listingId: string): Promise<void> {
  await buyerRequest(`/api/app/favorite?listingId=${encodeURIComponent(listingId)}`, accessToken, {
    method: "DELETE",
  });
}
