/* eslint-disable @next/next/no-img-element */
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { cache } from "react";
import {
  formatPrice,
  getPublicListings,
  publicPhotoUrl,
  vehicleLabel,
} from "@/lib/public-listings";
import { getPublicSeller } from "@/lib/public-sellers";
import { publicUrl } from "@/lib/site-url";
import styles from "../../page.module.css";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 12;
const GUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const loadSellerIdentity = cache((sellerId: string) => getPublicSeller(sellerId));
const loadSellerListings = cache((sellerId: string) =>
  getPublicListings({ sellerId, skip: 0, take: PAGE_SIZE }),
);

type RawSearchParams = Record<string, string | string[] | undefined>;
type PageProps = {
  params: Promise<{ sellerId: string }>;
  searchParams: Promise<RawSearchParams>;
};

function firstParam(value: string | string[] | undefined): string {
  return Array.isArray(value) ? value[0] ?? "" : value ?? "";
}

function skipParam(params: RawSearchParams): number {
  const raw = firstParam(params.skip).trim();
  const value = Number(raw);
  return Number.isInteger(value) && value > 0 ? value : 0;
}

function sellerHref(sellerId: string, skip: number): string {
  return skip > 0
    ? `/vendedores/${encodeURIComponent(sellerId)}?skip=${skip}`
    : `/vendedores/${encodeURIComponent(sellerId)}`;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { sellerId } = await params;
  if (!GUID_PATTERN.test(sellerId)) {
    return {
      title: "Vendedor não encontrado",
      robots: { index: false, follow: false },
    };
  }

  const page = await loadSellerListings(sellerId);
  const seller = await loadSellerIdentity(sellerId);
  const resolvedSeller = seller ?? page.items[0]?.seller;
  if (!resolvedSeller) {
    return {
      title: "Vendedor não encontrado",
      robots: { index: false, follow: false },
    };
  }

  const displayName = resolvedSeller.displayName ?? "Vendedor";
  const canonical = publicUrl(`/vendedores/${resolvedSeller.sellerId}`);
  const description =
    page.totalCount > 0
      ? `${page.totalCount} anúncio(s) público(s) de ${displayName} no Bom Pra Ti.`
      : `Perfil público de ${displayName} no Bom Pra Ti.`;
  const firstPhoto = page.items[0]?.photos[0];
  const socialImage = page.items[0] && firstPhoto ? publicPhotoUrl(page.items[0].id, firstPhoto.id) : undefined;

  return {
    title: displayName,
    description,
    alternates: { canonical },
    robots: { index: true, follow: true },
    openGraph: {
      type: "website",
      title: displayName,
      description,
      url: canonical,
      images: socialImage ? [{ url: socialImage, alt: displayName }] : undefined,
    },
    twitter: {
      card: socialImage ? "summary_large_image" : "summary",
      title: displayName,
      description,
      images: socialImage ? [socialImage] : undefined,
    },
  };
}

export default async function SellerHubPage({ params, searchParams }: PageProps) {
  const { sellerId } = await params;
  if (!GUID_PATTERN.test(sellerId)) notFound();

  const raw = await searchParams;
  const skip = skipParam(raw);
  const page = await getPublicListings({ sellerId, skip, take: PAGE_SIZE });
  const seller = await loadSellerIdentity(sellerId);
  if (!seller && page.totalCount === 0) notFound();

  const sellerFromListing = page.items[0]?.seller;
  const resolvedSeller = seller ?? sellerFromListing;
  if (!resolvedSeller) notFound();

  const displayName = resolvedSeller.displayName ?? "Vendedor";
  const hasPublicInventory = page.totalCount > 0;
  const hasPrevious = hasPublicInventory && skip > 0;
  const hasNext = hasPublicInventory && skip + page.items.length < page.totalCount;
  const currentPage = hasPublicInventory ? Math.floor(skip / PAGE_SIZE) + 1 : 1;
  const totalPages = hasPublicInventory ? Math.max(1, Math.ceil(page.totalCount / PAGE_SIZE)) : 1;

  return (
    <main className="shell">
      <nav className="back-nav" aria-label="Voltar para anúncios">
        <Link href="/">← Todos os anúncios</Link>
      </nav>

      <header className="hero">
        <p className="eyebrow">Vendedor</p>
        <h1>{displayName}</h1>
        <p className="lede">
          {hasPublicInventory
            ? `${page.totalCount} anúncio(s) publicado(s) por este vendedor.`
            : "Nenhum anúncio público disponível no momento."}
        </p>
      </header>

      <section aria-labelledby="seller-listings-title" className="listing-section">
        <div className="section-heading">
          <div>
            <p className="eyebrow">Anúncios</p>
            <h2 id="seller-listings-title">Veículos disponíveis</h2>
          </div>
          <p className="result-count">{page.totalCount} anúncio(s)</p>
        </div>

        {page.items.length === 0 ? (
          <div className="empty-state">
            <h3>{hasPublicInventory ? "Nenhum anúncio nesta página." : "Nenhum anúncio público disponível no momento."}</h3>
            <p>
              {hasPublicInventory
                ? "Volte para a página anterior para continuar vendo os anúncios deste vendedor."
                : "Este vendedor ainda não publicou anúncios visíveis ao público."}
            </p>
          </div>
        ) : (
          <div className="listing-grid">
            {page.items.map((listing) => {
              const cover = listing.photos[0];
              return (
                <article className="listing-card" key={listing.id}>
                  <Link className="listing-link" href={`/anuncios/${listing.id}`}>
                    <div className="listing-media">
                      {cover ? (
                        <img
                          alt={`Foto de ${listing.title}`}
                          loading="lazy"
                          src={publicPhotoUrl(listing.id, cover.id)}
                        />
                      ) : (
                        <div className="listing-placeholder">Sem foto</div>
                      )}
                    </div>
                    <div className="listing-body">
                      <p className="listing-vehicle">{vehicleLabel(listing)}</p>
                      <h3>{listing.title}</h3>
                      <p className="listing-price">{formatPrice(listing.price)}</p>
                      <p className="listing-location">
                        {listing.city} · {listing.stateCode}
                      </p>
                    </div>
                  </Link>
                </article>
              );
            })}
          </div>
        )}

        {(hasPrevious || hasNext) && (
          <nav aria-label="Paginação dos anúncios do vendedor" className={styles.pagination}>
            {hasPrevious ? (
              <Link href={sellerHref(resolvedSeller.sellerId, Math.max(0, skip - PAGE_SIZE))}>
                ← Anterior
              </Link>
            ) : (
              <span aria-hidden="true" />
            )}
            <span>
              Página {Math.min(currentPage, totalPages)} de {totalPages}
            </span>
            {hasNext ? (
              <Link href={sellerHref(resolvedSeller.sellerId, skip + PAGE_SIZE)}>Próxima →</Link>
            ) : (
              <span aria-hidden="true" />
            )}
          </nav>
        )}
      </section>
    </main>
  );
}
