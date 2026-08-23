export type SellerProfile = {
  id: string;
  displayName: string;
  whatsAppNumber: string;
};

export type UpdateSellerProfileInput = {
  displayName: string;
  whatsAppNumber: string;
};

export type SellerListing = {
  id: string;
  sellerId: string;
  vehicleId: string;
  title: string;
  price: number;
  description: string;
  manufactureYear: number | null;
  mileageKm: number | null;
  color: string | null;
  city: string;
  stateCode: string;
  status: string;
  concurrencyStamp: string;
};

function apiBaseUrl(): string {
  return (
    process.env.NEXT_PUBLIC_BPT_API_BASE_URL ??
    process.env.NEXT_PUBLIC_BPT_AUTHORITY ??
    "http://127.0.0.1:5093"
  ).replace(/\/$/, "");
}

async function apiRequest(
  path: string,
  accessToken: string,
  init?: RequestInit,
): Promise<Response> {
  const headers = new Headers(init?.headers);
  headers.set("Authorization", `Bearer ${accessToken}`);
  if (init?.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

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
    throw new Error(
      `A API Seller respondeu ${response.status}${detail ? `: ${detail}` : "."}`,
    );
  }

  return response;
}

export async function getSellerProfile(accessToken: string): Promise<SellerProfile | null> {
  const response = await apiRequest("/api/app/seller-profile/current", accessToken);
  if (response.status === 204) {
    return null;
  }

  return (await response.json()) as SellerProfile;
}

export async function upsertSellerProfile(
  accessToken: string,
  input: UpdateSellerProfileInput,
): Promise<SellerProfile> {
  const response = await apiRequest("/api/app/seller-profile/upsert", accessToken, {
    method: "POST",
    body: JSON.stringify(input),
  });

  return (await response.json()) as SellerProfile;
}

export async function getMyListings(accessToken: string): Promise<SellerListing[]> {
  const response = await apiRequest("/api/app/seller-listing-query/mine", accessToken);
  return (await response.json()) as SellerListing[];
}
