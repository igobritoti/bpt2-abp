"use client";

import { FormEvent, useEffect, useState } from "react";
import type { User } from "oidc-client-ts";

import { formatPrice } from "../../lib/public-listings";
import {
  getMyListings,
  getSellerProfile,
  type SellerListing,
  type SellerProfile,
  upsertSellerProfile,
} from "../../lib/seller-api";
import { getCurrentSellerUser, getSellerUserManager } from "../../lib/seller-auth";

export default function SellerEntryPage() {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<SellerProfile | null>(null);
  const [listings, setListings] = useState<SellerListing[]>([]);
  const [displayName, setDisplayName] = useState("");
  const [whatsAppNumber, setWhatsAppNumber] = useState("");
  const [loading, setLoading] = useState(true);
  const [savingProfile, setSavingProfile] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    async function loadSellerShell() {
      try {
        const currentUser = await getCurrentSellerUser();
        setUser(currentUser);
        if (!currentUser) {
          return;
        }

        const [currentProfile, currentListings] = await Promise.all([
          getSellerProfile(currentUser.access_token),
          getMyListings(currentUser.access_token),
        ]);

        setProfile(currentProfile);
        setListings(currentListings);
        setDisplayName(currentProfile?.displayName ?? "");
        setWhatsAppNumber(currentProfile?.whatsAppNumber ?? "");
      } catch (reason: unknown) {
        setError(reason instanceof Error ? reason.message : "Não foi possível carregar a área do vendedor.");
      } finally {
        setLoading(false);
      }
    }

    void loadSellerShell();
  }, []);

  async function signIn() {
    setError(null);
    await getSellerUserManager().signinRedirect();
  }

  async function signOut() {
    setError(null);
    await getSellerUserManager().signoutRedirect();
  }

  async function saveProfile(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!user) {
      return;
    }

    setError(null);
    setNotice(null);
    setSavingProfile(true);
    try {
      const saved = await upsertSellerProfile(user.access_token, {
        displayName,
        whatsAppNumber,
      });
      setProfile(saved);
      setDisplayName(saved.displayName);
      setWhatsAppNumber(saved.whatsAppNumber);
      setNotice("Perfil salvo. O WhatsApp exibido abaixo é o valor canônico devolvido pelo backend.");
    } catch (reason: unknown) {
      setError(reason instanceof Error ? reason.message : "Não foi possível salvar o perfil.");
    } finally {
      setSavingProfile(false);
    }
  }

  return (
    <main className="shell seller-shell">
      <header className="seller-dashboard-header">
        <div>
          <p className="eyebrow">Área do vendedor</p>
          <h1>Seus anúncios.</h1>
          <p className="lede">
            Perfil e anúncios são carregados pelas APIs autenticadas do BPT2. Ownership e normalização continuam no backend.
          </p>
        </div>
        {user ? (
          <button className="secondary-action" type="button" onClick={signOut}>
            Sair
          </button>
        ) : null}
      </header>

      {loading ? <p className="seller-shell-status">Verificando sessão…</p> : null}
      {error ? <p className="seller-auth-error">{error}</p> : null}
      {notice ? <p className="seller-auth-notice">{notice}</p> : null}

      {!loading && !user ? (
        <section className="seller-auth-card" aria-live="polite">
          <h2>Entrar como vendedor</h2>
          <p>A senha é informada somente no Auth Server. Este cliente usa Authorization Code + PKCE.</p>
          <button className="primary-action" type="button" onClick={signIn}>
            Entrar
          </button>
        </section>
      ) : null}

      {!loading && user ? (
        <div className="seller-dashboard-grid">
          <section className="seller-panel">
            <div className="seller-panel-heading">
              <div>
                <p className="eyebrow">Perfil</p>
                <h2>{profile ? "Dados públicos" : "Complete seu perfil"}</h2>
              </div>
            </div>

            <form className="seller-profile-form" onSubmit={saveProfile}>
              <label>
                Nome de exibição
                <input
                  name="displayName"
                  value={displayName}
                  onChange={(event) => setDisplayName(event.target.value)}
                  required
                  maxLength={160}
                  autoComplete="organization"
                />
              </label>

              <label>
                WhatsApp com código do país
                <input
                  name="whatsAppNumber"
                  value={whatsAppNumber}
                  onChange={(event) => setWhatsAppNumber(event.target.value)}
                  required
                  inputMode="tel"
                  autoComplete="tel"
                  placeholder="+55 (11) 99999-8877"
                />
              </label>

              <p className="seller-form-help">
                Formatação é aceita na entrada; o backend devolve e persiste o número canônico somente com dígitos.
              </p>

              <button className="primary-action" type="submit" disabled={savingProfile}>
                {savingProfile ? "Salvando…" : "Salvar perfil"}
              </button>
            </form>
          </section>

          <section className="seller-panel seller-listings-panel">
            <div className="seller-panel-heading">
              <div>
                <p className="eyebrow">Marketplace</p>
                <h2>Meus anúncios</h2>
              </div>
              <span className="seller-count">{listings.length}</span>
            </div>

            {listings.length === 0 ? (
              <div className="empty-state seller-empty-state">
                <h3>Nenhum anúncio ainda.</h3>
                <p>A criação do primeiro Draft entra no próximo checkpoint deste plano.</p>
              </div>
            ) : (
              <div className="seller-listing-list">
                {listings.map((listing) => (
                  <article className="seller-listing-row" key={listing.id}>
                    <div>
                      <p className="seller-listing-status">{listing.status}</p>
                      <h3>{listing.title}</h3>
                      <p className="seller-listing-location">
                        {listing.city} / {listing.stateCode}
                      </p>
                    </div>
                    <p className="seller-listing-price">{formatPrice(listing.price)}</p>
                  </article>
                ))}
              </div>
            )}
          </section>
        </div>
      ) : null}
    </main>
  );
}
