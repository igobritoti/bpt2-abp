/* eslint-disable @next/next/no-img-element */
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { cache } from "react";
import FavoriteButton from "./FavoriteButton";
import WhatsAppContactButton from "./WhatsAppContactButton";
import {
  formatPrice,
  getPublicListing,
  publicPhotoUrl,
  vehicleLabel,
  whatsAppUrl,
} from "@/lib/public-listings";

export const dynamic = "force-dynamic";

const loadListing = cache((id: string) => getPublicListing(id));

type PageProps = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  const listing = await loadListing(id);
  if (!listing) return { title: "Anúncio não encontrado" };
  const vehicle = vehicleLabel(listing);
  return { title: listing.title, description: `${vehicle} em ${listing.city}/${listing.stateCode}. ${formatPrice(listing.price)}.` };
}

export default async function ListingDetailPage({ params }: PageProps) {
  const { id } = await params;
  const listing = await loadListing(id);
  if (!listing) notFound();
  const contactUrl = whatsAppUrl(listing.seller.whatsAppNumber);

  return (
    <main className="shell detail-shell">
      <nav className="back-nav" aria-label="Voltar para anúncios"><Link href="/">← Todos os anúncios</Link></nav>
      <article>
        <header className="detail-header">
          <div><p className="eyebrow">{vehicleLabel(listing)}</p><h1>{listing.title}</h1><p className="detail-location">{listing.city} · {listing.stateCode}</p></div>
          <p className="detail-price">{formatPrice(listing.price)}</p>
        </header>
        <section aria-label="Fotos do anúncio" className="photo-grid">
          {listing.photos.length === 0 ? <div className="detail-photo-placeholder">Este anúncio ainda não tem fotos.</div> : listing.photos.map((photo, index) => (
            <figure className={index === 0 ? "photo-main" : "photo-secondary"} key={photo.id}><img alt={`${listing.title} — foto ${index + 1}`} src={publicPhotoUrl(listing.id, photo.id)} /></figure>
          ))}
        </section>
        <div className="detail-columns">
          <div className="detail-content">
            <section className="detail-section" aria-labelledby="facts-title">
              <p className="eyebrow">Veículo</p><h2 id="facts-title">Dados do anúncio</h2>
              <dl className="facts-grid">
                <div><dt>Ano do modelo</dt><dd>{listing.vehicle.modelYear}</dd></div>
                {listing.manufactureYear ? <div><dt>Ano de fabricação</dt><dd>{listing.manufactureYear}</dd></div> : null}
                {listing.mileageKm !== null ? <div><dt>Quilometragem</dt><dd>{new Intl.NumberFormat("pt-BR").format(listing.mileageKm)} km</dd></div> : null}
                {listing.color ? <div><dt>Cor</dt><dd>{listing.color}</dd></div> : null}
                <div><dt>Versão</dt><dd>{listing.vehicle.version}</dd></div>
              </dl>
            </section>
            <section className="detail-section" aria-labelledby="description-title"><p className="eyebrow">Descrição</p><h2 id="description-title">Sobre este veículo</h2><p className="description-text">{listing.description}</p></section>
          </div>
          <aside className="seller-card" aria-labelledby="seller-title">
            <p className="eyebrow">Vendedor</p><h2 id="seller-title">{listing.seller.displayName ?? "Vendedor"}</h2><p>Fale diretamente com o responsável por este anúncio.</p>
            <FavoriteButton listingId={listing.id} />
            <Link className="secondary-action" href="/favoritos">Meus favoritos</Link>
            {contactUrl ? <WhatsAppContactButton listingId={listing.id} /> : <p className="contact-unavailable">Contato indisponível neste momento.</p>}
          </aside>
        </div>
      </article>
    </main>
  );
}
