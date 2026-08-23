export type PublicListingVehicle = {
  id: string;
  brand: string;
  model: string;
  generation: string;
  version: string;
  modelYear: number;
};

export type PublicListingSeller = {
  sellerId: string;
  displayName: string | null;
  whatsAppNumber: string | null;
};

export type PublicListingPhoto = {
  id: string;
  mediaAssetId: string;
  contentType: string;
  length: number;
  sortOrder: number;
};

export type PublicListing = {
  id: string;
  vehicleId: string;
  vehicle: PublicListingVehicle;
  seller: PublicListingSeller;
  title: string;
  price: number;
  description: string;
  manufactureYear: number | null;
  mileageKm: number | null;
  color: string | null;
  city: string;
  stateCode: string;
  photos: PublicListingPhoto[];
};

type PagedResult<T> = {
  totalCount: number;
  items: T[];
};

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

function publicApiBaseUrl(): string {
  const value = process.env.NEXT_PUBLIC_BPT_API_BASE_URL ?? process.env.BPT_API_BASE_URL;
  if (!value) {
    throw new Error("NEXT_PUBLIC_BPT_API_BASE_URL or BPT_API_BASE_URL is required at runtime.");
  }

  return trimTrailingSlash(value);
}

export async function getPublicListings(take = 24): Promise<PagedResult<PublicListing>> {
  const url = new URL("/api/app/public-listing", `${serverApiBaseUrl()}/`);
  url.searchParams.set("Skip", "0");
  url.searchParams.set("Take", String(take));

  const response = await fetch(url, {
    cache: "no-store",
    headers: { Accept: "application/json" },
  });

  if (!response.ok) {
    throw new Error(`Public Listing list failed with HTTP ${response.status}.`);
  }

  return (await response.json()) as PagedResult<PublicListing>;
}

export async function getPublicListing(id: string): Promise<PublicListing | null> {
  const response = await fetch(
    new URL(`/api/app/public-listing/${encodeURIComponent(id)}`, `${serverApiBaseUrl()}/`),
    {
      cache: "no-store",
      headers: { Accept: "application/json" },
    },
  );

  if (response.status === 404 || response.status === 204) {
    return null;
  }

  if (!response.ok) {
    throw new Error(`Public Listing detail failed with HTTP ${response.status}.`);
  }

  const listing = (await response.json()) as PublicListing | null;
  return listing ?? null;
}

export function publicPhotoUrl(listingId: string, photoId: string): string {
  return `${publicApiBaseUrl()}/api/app/public-listing/${encodeURIComponent(listingId)}/photo/${encodeURIComponent(photoId)}`;
}

export function whatsAppUrl(whatsAppNumber: string | null): string | null {
  if (!whatsAppNumber || !/^\d{8,15}$/.test(whatsAppNumber)) {
    return null;
  }

  return `https://wa.me/${whatsAppNumber}`;
}

export function formatPrice(value: number): string {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
    maximumFractionDigits: 0,
  }).format(value);
}

export function vehicleLabel(listing: PublicListing): string {
  const parts = [listing.vehicle.brand, listing.vehicle.model, listing.vehicle.version]
    .map((value) => value?.trim())
    .filter(Boolean);
  return parts.join(" ");
}
