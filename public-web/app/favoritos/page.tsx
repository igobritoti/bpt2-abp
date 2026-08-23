"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import type { User } from "oidc-client-ts";
import { getMyFavorites, removeFavorite } from "../../lib/buyer-api";
import { getCurrentBuyerUser, getBuyerUserManager, signInBuyer } from "../../lib/buyer-auth";
import { formatPrice, type PublicListing } from "../../lib/public-listings";

export default function FavoritesPage() {
  const [user, setUser] = useState<User | null>(null);
  const [favorites, setFavorites] = useState<PublicListing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function load() {
      try {
        const currentUser = await getCurrentBuyerUser();
        setUser(currentUser);
        if (currentUser) {
          setFavorites(await getMyFavorites(currentUser.access_token));
        }
      } catch (reason: unknown) {
        setError(reason instanceof Error ? reason.message : "Não foi possível carregar seus favoritos.");
      } finally {
        setLoading(false);
      }
    }
    void load();
  }, []);

  async function remove(listingId: string) {
    if (!user) return;
    setError(null);
    try {
      await removeFavorite(user.access_token, listingId);
      setFavorites((items) => items.filter((item) => item.id !== listingId));
    } catch (reason: unknown) {
      setError(reason instanceof Error ? reason.message : "Não foi possível remover o favorito.");
    }
  }

  return (
    <main className="shell seller-shell">
      <nav className="back-nav" aria-label="Voltar para anúncios">
        <Link href="/">← Todos os anúncios</Link>
      </nav>
      <header className="seller-dashboard-header">
        <div>
          <p className="eyebrow">Conta do comprador</p>
          <h1>Meus favoritos.</h1>
          <p className="lede">Salve anúncios publicados para reencontrá-los enquanto continuarem públicos.</p>
        </div>
        {user ? (
          <button className="secondary-action" type="button" onClick={() => getBuyerUserManager().signoutRedirect()}>
            Sair
          </button>
        ) : null}
      </header>

      {loading ? <p className="seller-shell-status">Verificando sessão…</p> : null}
      {error ? <p className="seller-auth-error">{error}</p> : null}

      {!loading && !user ? (
        <section className="seller-auth-card">
          <h2>Entre para salvar favoritos</h2>
          <p>A senha fica no Auth Server. O cliente Buyer usa Authorization Code + PKCE.</p>
          <button className="primary-action" type="button" onClick={() => signInBuyer("/favoritos")}>
            Entrar
          </button>
        </section>
      ) : null}

      {!loading && user ? (
        <section className="listing-section" aria-labelledby="favorite-list-title">
          <div className="section-heading">
            <h2 id="favorite-list-title">Anúncios salvos</h2>
            <p className="result-count">{favorites.length} favorito(s)</p>
          </div>
          {favorites.length === 0 ? (
            <div className="empty-state">
              <h3>Nenhum favorito público agora.</h3>
              <p>Salve um anúncio na página de detalhes. Se ele for pausado, deixa de aparecer aqui.</p>
            </div>
          ) : (
            <div className="listing-grid">
              {favorites.map((listing) => (
                <article className="listing-card" key={listing.id}>
                  <div className="listing-body">
                    <h3><Link href={`/anuncios/${listing.id}`}>{listing.title}</Link></h3>
                    <p className="listing-price">{formatPrice(listing.price)}</p>
                    <p className="listing-location">{listing.city} · {listing.stateCode}</p>
                    <button className="secondary-action" type="button" onClick={() => remove(listing.id)}>
                      Remover dos favoritos
                    </button>
                  </div>
                </article>
              ))}
            </div>
          )}
        </section>
      ) : null}
    </main>
  );
}
