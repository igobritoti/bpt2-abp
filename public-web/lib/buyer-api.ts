import type { PublicListing, PublicListingSearch } from "./public-listings";

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
    throw new Error(`A API Buyer respondeu ${response.status}${detail ? `: ${detail}` : "."}`);
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

export async function isListingReported(accessToken: string, listingId: string): Promise<boolean> {
  const response = await buyerRequest(
    `/api/app/listing-report/is-reported/${encodeURIComponent(listingId)}`,
    accessToken,
  );
  return (await response.json()) as boolean;
}

export async function reportListing(accessToken: string, listingId: string): Promise<void> {
  await buyerRequest(
    `/api/app/listing-report/report/${encodeURIComponent(listingId)}`,
    accessToken,
    { method: "POST" },
  );
}

export type SavedSearch = Omit<PublicListingSearch, "sort" | "skip" | "take"> & {
  id: string;
  alertEnabled: boolean;
  alertEnabledAtUtc?: string;
  createdAtUtc: string;
};

export type SavedSearchCriteria = Omit<PublicListingSearch, "sort" | "skip" | "take">;

export async function createSavedSearch(
  accessToken: string,
  criteria: SavedSearchCriteria,
): Promise<SavedSearch> {
  const response = await buyerRequest("/api/app/saved-search", accessToken, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(criteria),
  });
  return (await response.json()) as SavedSearch;
}

export async function getMySavedSearches(accessToken: string): Promise<SavedSearch[]> {
  const response = await buyerRequest("/api/app/saved-search/mine", accessToken);
  return (await response.json()) as SavedSearch[];
}

export async function setSavedSearchMonitoring(
  accessToken: string,
  id: string,
  enabled: boolean,
): Promise<SavedSearch> {
  const response = await buyerRequest(
    `/api/app/saved-search/${encodeURIComponent(id)}/set-alert-enabled?enabled=${enabled}`,
    accessToken,
    { method: "POST" },
  );
  return (await response.json()) as SavedSearch;
}

export async function deleteSavedSearch(accessToken: string, id: string): Promise<void> {
  await buyerRequest(`/api/app/saved-search/${encodeURIComponent(id)}`, accessToken, {
    method: "DELETE",
  });
}
