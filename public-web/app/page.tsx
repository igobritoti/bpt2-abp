/* eslint-disable @next/next/no-img-element */
import type { Metadata } from "next";
import Link from "next/link";
import {
  formatPrice,
  getPublicListings,
  type PublicListingSearch,
  type PublicListingSort,
  publicPhotoUrl,
  vehicleLabel,
} from "@/lib/public-listings";
import { publicUrl } from "@/lib/site-url";
import SavedSearchButton from "./saved-search-button";
import styles from "./page.module.css";

export const dynamic = "force-dynamic";

const HOME_TITLE = "Bom Pra Ti";
const HOME_DESCRIPTION = "Encontre veículos e fale diretamente com o vendedor.";

export const metadata: Metadata = {
  openGraph: {
    type: "website",
    title: HOME_TITLE,
    description: HOME_DESCRIPTION,
    url: publicUrl("/"),
  },
  twitter: {
    card: "summary",
    title: HOME_TITLE,
    description: HOME_DESCRIPTION,
  },
};

const DEFAULT_TAKE = 12;
const MAX_UI_TAKE = 24;

type RawSearchParams = Record<string, string | string[] | undefined>;
type HomePageProps = {
  searchParams: Promise<RawSearchParams>;
};

function firstParam(value: string | string[] | undefined): string {
  return Array.isArray(value) ? value[0] ?? "" : value ?? "";
}

function textParam(params: RawSearchParams, name: string): string {
  return firstParam(params[name]).trim();
}

function numberParam(params: RawSearchParams, name: string): number | undefined {
  const raw = firstParam(params[name]).trim();
  if (!raw) {
    return undefined;
  }
  const value = Number(raw);
  return Number.isFinite(value) ? value : undefined;
}

function integerParam(params: RawSearchParams, name: string): number | undefined {
  const value = numberParam(params, name);
  return value !== undefined && Number.isInteger(value) ? value : undefined;
}

function sortParam(params: RawSearchParams): PublicListingSort | undefined {
  const value = textParam(params, "sort").toLowerCase();
  return value === "price-asc" || value === "price-desc" ? value : undefined;
}

function discoveryHref(search: PublicListingSearch, skip: number, take: number): string {
  const params = new URLSearchParams();

  const setText = (name: string, value: string | undefined) => {
    if (value) {
      params.set(name, value);
    }
  };
  const setNumber = (name: string, value: number | undefined) => {
    if (value !== undefined) {
      params.set(name, String(value));
    }
  };

  setText("vehicleId", search.vehicleId);
  setText("sellerId", search.sellerId);
  setText("query", search.query);
  setText("brand", search.brand);
  setText("model", search.model);
  setText("city", search.city);
  setText("stateCode", search.stateCode);
  setNumber("minModelYear", search.minModelYear);
  setNumber("maxModelYear", search.maxModelYear);
  setNumber("minPrice", search.minPrice);
  setNumber("maxPrice", search.maxPrice);
  setNumber("minMileageKm", search.minMileageKm);
  setNumber("maxMileageKm", search.maxMileageKm);
  setText("sort", search.sort);
  if (skip > 0) {
    params.set("skip", String(skip));
  }
  params.set("take", String(take));

  return `/?${params.toString()}`;
}

export default async function HomePage({ searchParams }: HomePageProps) {
  const raw = await searchParams;
  const vehicleId = textParam(raw, "vehicleId");
  const sellerId = textParam(raw, "sellerId");
  const query = textParam(raw, "query");
  const brand = textParam(raw, "brand");
  const model = textParam(raw, "model");
  const city = textParam(raw, "city");
  const stateCode = textParam(raw, "stateCode");
  const minModelYear = integerParam(raw, "minModelYear");
  const maxModelYear = integerParam(raw, "maxModelYear");
  const minPrice = numberParam(raw, "minPrice");
  const maxPrice = numberParam(raw, "maxPrice");
  const minMileageKm = integerParam(raw, "minMileageKm");
  const maxMileageKm = integerParam(raw, "maxMileageKm");
  const sort = sortParam(raw);
  const skip = Math.max(0, integerParam(raw, "skip") ?? 0);
  const take = Math.min(
    MAX_UI_TAKE,
    Math.max(1, integerParam(raw, "take") ?? DEFAULT_TAKE),
  );

  const search: PublicListingSearch = {
    vehicleId: vehicleId || undefined,
    sellerId: sellerId || undefined,
    query: query || undefined,
    brand: brand || undefined,
    model: model || undefined,
    city: city || undefined,
    stateCode: stateCode || undefined,
    minModelYear,
    maxModelYear,
    minPrice,
    maxPrice,
    minMileageKm,
    maxMileageKm,
    sort,
    skip,
    take,
  };
  const savedSearchCriteria = {
    vehicleId: vehicleId || undefined,
    sellerId: sellerId || undefined,
    query: query || undefined,
    brand: brand || undefined,
    model: model || undefined,
    city: city || undefined,
    stateCode: stateCode || undefined,
    minModelYear,
    maxModelYear,
    minPrice,
    maxPrice,
    minMileageKm,
    maxMileageKm,
  };
  const page = await getPublicListings(search);
  const hasSemanticFilters = Boolean(
    vehicleId ||
      sellerId ||
      query ||
      brand ||
      model ||
      city ||
      stateCode ||
      minModelYear !== undefined ||
      maxModelYear !== undefined ||
      minPrice !== undefined ||
      maxPrice !== undefined ||
      minMileageKm !== undefined ||
      maxMileageKm !== undefined,
  );
  const hasActiveFilters = hasSemanticFilters || Boolean(sort);
  const hasPrevious = skip > 0;
  const hasNext = skip + page.items.length < page.totalCount;
  const currentPage = Math.floor(skip / take) + 1;
  const totalPages = Math.max(1, Math.ceil(page.totalCount / take));

  return (
    <main className="shell">
      <header className="hero">
        <p className="eyebrow">Bom Pra Ti</p>
        <h1>Encontre o próximo carro.</h1>
        <p className="lede">
          Busque anúncios públicos, refine pelo veículo, localização, quilometragem e preço e fale direto com o vendedor.
        </p>
        <p><Link href="/buscas-salvas">Minhas buscas salvas</Link></p>
      </header>

      <section className={styles.discovery} aria-labelledby="discovery-title">
        <div className={styles.discoveryHeading}>
          <div>
            <p className="eyebrow">Descoberta</p>
            <h2 id="discovery-title">Refine sua busca</h2>
          </div>
          <div>
            {hasSemanticFilters ? <SavedSearchButton criteria={savedSearchCriteria} /> : null}
            {hasActiveFilters ? (
              <Link className={styles.clearFilters} href="/">
                Limpar filtros
              </Link>
            ) : null}
          </div>
        </div>

        <form action="/" className={styles.discoveryForm} method="get">
          {vehicleId ? <input name="vehicleId" type="hidden" value={vehicleId} /> : null}
          {sellerId ? <input name="sellerId" type="hidden" value={sellerId} /> : null}
          <label className={styles.queryField}>
            Busca
            <input
              defaultValue={query}
              name="query"
              placeholder="Ex.: Civic, Corolla, SUV..."
              type="search"
            />
          </label>

          <label>
            Marca
            <input defaultValue={brand} name="brand" placeholder="Ex.: Honda" />
          </label>

          <label>
            Modelo
            <input defaultValue={model} name="model" placeholder="Ex.: Civic" />
          </label>

          <label>
            Cidade
            <input defaultValue={city} name="city" placeholder="Ex.: São Paulo" />
          </label>

          <label>
            UF
            <input
              autoCapitalize="characters"
              defaultValue={stateCode}
              maxLength={2}
              name="stateCode"
              placeholder="Ex.: SP"
            />
          </label>

          <label>
            Ano mínimo
            <input
              defaultValue={minModelYear ?? ""}
              inputMode="numeric"
              name="minModelYear"
              type="number"
            />
          </label>

          <label>
            Ano máximo
            <input
              defaultValue={maxModelYear ?? ""}
              inputMode="numeric"
              name="maxModelYear"
              type="number"
            />
          </label>

          <label>
            Km mínima
            <input
              defaultValue={minMileageKm ?? ""}
              inputMode="numeric"
              min="0"
              name="minMileageKm"
              step="1"
              type="number"
            />
          </label>

          <label>
            Km máxima
            <input
              defaultValue={maxMileageKm ?? ""}
              inputMode="numeric"
              min="0"
              name="maxMileageKm"
              step="1"
              type="number"
            />
          </label>

          <label>
            Preço mínimo
            <input
              defaultValue={minPrice ?? ""}
              inputMode="decimal"
              min="0"
              name="minPrice"
              step="0.01"
              type="number"
            />
          </label>

          <label>
            Preço máximo
            <input
              defaultValue={maxPrice ?? ""}
              inputMode="decimal"
              min="0"
              name="maxPrice"
              step="0.01"
              type="number"
            />
          </label>

          <label>
            Ordenar
            <select defaultValue={sort ?? ""} name="sort">
              <option value="">Padrão</option>
              <option value="price-asc">Menor preço</option>
              <option value="price-desc">Maior preço</option>
            </select>
          </label>

          <input name="take" type="hidden" value={take} />
          <button className={styles.submitFilters} type="submit">
            Buscar anúncios
          </button>
        </form>
      </section>

      <section aria-labelledby="listings-title" className="listing-section">
        <div className="section-heading">
          <div>
            <p className="eyebrow">Anúncios</p>
            <h2 id="listings-title">Veículos disponíveis</h2>
          </div>
          <p className="result-count">{page.totalCount} anúncio(s)</p>
        </div>

        {page.items.length === 0 ? (
          <div className="empty-state">
            <h3>{hasActiveFilters ? "Nenhum anúncio encontrado." : "Nenhum anúncio publicado agora."}</h3>
            <p>
              {hasActiveFilters
                ? "Ajuste ou limpe os filtros para ampliar a busca."
                : "Novos veículos aparecerão aqui depois de publicados pelo vendedor."}
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
          <nav aria-label="Paginação dos anúncios" className={styles.pagination}>
            {hasPrevious ? (
              <Link href={discoveryHref(search, Math.max(0, skip - take), take)}>
                ← Anterior
              </Link>
            ) : (
              <span aria-hidden="true" />
            )}
            <span>
              Página {Math.min(currentPage, totalPages)} de {totalPages}
            </span>
            {hasNext ? (
              <Link href={discoveryHref(search, skip + take, take)}>Próxima →</Link>
            ) : (
              <span aria-hidden="true" />
            )}
          </nav>
        )}
      </section>
    </main>
  );
}
