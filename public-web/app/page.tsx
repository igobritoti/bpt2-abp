/* eslint-disable @next/next/no-img-element */
import Link from "next/link";
import {
  formatPrice,
  getPublicListings,
  publicPhotoUrl,
  vehicleLabel,
} from "@/lib/public-listings";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const page = await getPublicListings();

  return (
    <main className="shell">
      <header className="hero">
        <p className="eyebrow">Bom Pra Ti</p>
        <h1>Encontre o próximo carro.</h1>
        <p className="lede">
          Anúncios públicos de veículos com contato direto com o vendedor.
        </p>
      </header>

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
            <h3>Nenhum anúncio publicado agora.</h3>
            <p>Novos veículos aparecerão aqui depois de publicados pelo vendedor.</p>
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
      </section>
    </main>
  );
}
