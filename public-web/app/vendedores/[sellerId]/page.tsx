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
import { publicUrl } from "@/lib/site-url";
import styles from "../../page.module.css";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 12;
const GUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const loadSellerIdentity = cache((sellerId: string) =>
  getPublicListings({ sellerId, skip: 0, take: 1 }),
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

  const page = await loadSellerIdentity(sellerId);
  const seller = page.items[0]?.seller;
  if (!seller) {
    return {
      title: "Vendedor não encontrado",
      robots: { index: false, follow: false },
    };
  }

  const displayName = seller.displayName ?? "Vendedor";
  const canonical = publicUrl(`/vendedores/${seller.sellerId}`);
  const description = `${page.totalCount} anúncio(s) público(s) de ${displayName} no Bom Pra Ti.`;

  return {
    title: displayName,
    description,
    alternates: { canonical },
    robots: { index: true, follow: true },
  };
}

export default async function SellerHubPage({ params, searchParams }: PageProps) {
  const { sellerId } = await params;
  if (!GUID_PATTERN.test(sellerId)) notFound();

  const raw = await searchParams;
  const skip = skipParam(raw);
  const page = await getPublicListings({ sellerId, skip, take: PAGE_SIZE });
  if (page.totalCount === 0) notFound();

  const identityPage = page.items.length > 0 ? page : await loadSellerIdentity(sellerId);
  const seller = identityPage.items[0]?.seller;
  if (!seller) notFound();

  const displayName = seller.displayName ?? "Vendedor";
  const hasPrevious = skip > 0;
  const hasNext = skip + page.items.length < page.totalCount;
  const currentPage = Math.floor(skip / PAGE_SIZE) + 1;
  const totalPages = Math.max(1, Math.ceil(page.totalCount / PAGE_SIZE));

  return (
    <main className="shell">
      <nav className="back-nav" aria-label="Voltar para anúncios">
        <Link href="/">← Todos os anúncios</Link>
      </nav>

      <header className="hero">
        <p className="eyebrow">Vendedor</p>
        <h1>{displayName}</h1>
        <p className="lede">{page.totalCount} anúncio(s) publicado(s) por este vendedor.</p>
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
            <h3>Nenhum anúncio nesta página.</h3>
            <p>Volte para a página anterior para continuar vendo os anúncios deste vendedor.</p>
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
              <Link href={sellerHref(seller.sellerId, Math.max(0, skip - PAGE_SIZE))}>
                ← Anterior
              </Link>
            ) : (
              <span aria-hidden="true" />
            )}
            <span>
              Página {Math.min(currentPage, totalPages)} de {totalPages}
            </span>
            {hasNext ? (
              <Link href={sellerHref(seller.sellerId, skip + PAGE_SIZE)}>Próxima →</Link>
            ) : (
              <span aria-hidden="true" />
            )}
          </nav>
        )}
      </section>
    </main>
  );
}
