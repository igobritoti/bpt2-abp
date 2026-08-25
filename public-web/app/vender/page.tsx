"use client";

import Link from "next/link";
import { FormEvent, useEffect, useState } from "react";
import type { User } from "oidc-client-ts";

import { formatPrice } from "../../lib/public-listings";
import {
  closeSellerLead,
  getMyLeads,
  getMyListings,
  getSellerProfile,
  markSellerLeadContacted,
  type SellerLead,
  type SellerLeadOutcome,
  type SellerListing,
  type SellerProfile,
  upsertSellerProfile,
} from "../../lib/seller-api";
import { getCurrentSellerUser, getSellerUserManager } from "../../lib/seller-auth";

function leadStatusLabel(lead: SellerLead): string {
  if (lead.closedAtUtc) {
    return lead.outcome === "Won" ? "Fechado · Vendido" : "Fechado · Sem venda";
  }
  return lead.contactedAtUtc ? "Atendido" : "Novo";
}

export default function SellerEntryPage() {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<SellerProfile | null>(null);
  const [listings, setListings] = useState<SellerListing[]>([]);
  const [leads, setLeads] = useState<SellerLead[]>([]);
  const [displayName, setDisplayName] = useState("");
  const [whatsAppNumber, setWhatsAppNumber] = useState("");
  const [loading, setLoading] = useState(true);
  const [savingProfile, setSavingProfile] = useState(false);
  const [updatingLeadId, setUpdatingLeadId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    async function loadSellerShell() {
      try {
        const currentUser = await getCurrentSellerUser();
        setUser(currentUser);
        if (!currentUser) return;

        const [currentProfile, currentListings, currentLeads] = await Promise.all([
          getSellerProfile(currentUser.access_token),
          getMyListings(currentUser.access_token),
          getMyLeads(currentUser.access_token),
        ]);

        setProfile(currentProfile);
        setListings(currentListings);
        setLeads(currentLeads);
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
    if (!user) return;

    setError(null);
    setNotice(null);
    setSavingProfile(true);
    try {
      const saved = await upsertSellerProfile(user.access_token, { displayName, whatsAppNumber });
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

  async function reloadLeads(accessToken: string) {
    setLeads(await getMyLeads(accessToken));
  }

  async function markLeadContacted(leadId: string) {
    if (!user) return;
    setError(null);
    setNotice(null);
    setUpdatingLeadId(leadId);
    try {
      await markSellerLeadContacted(user.access_token, leadId);
      await reloadLeads(user.access_token);
      setNotice("Lead marcado como atendido.");
    } catch (reason: unknown) {
      setError(reason instanceof Error ? reason.message : "Não foi possível atualizar o Lead.");
    } finally {
      setUpdatingLeadId(null);
    }
  }

  async function closeLead(leadId: string, outcome: SellerLeadOutcome) {
    if (!user) return;
    setError(null);
    setNotice(null);
    setUpdatingLeadId(leadId);
    try {
      await closeSellerLead(user.access_token, leadId, outcome);
      await reloadLeads(user.access_token);
      setNotice(outcome === "Won" ? "Lead encerrado como vendido." : "Lead encerrado sem venda.");
    } catch (reason: unknown) {
      setError(reason instanceof Error ? reason.message : "Não foi possível encerrar o Lead.");
    } finally {
      setUpdatingLeadId(null);
    }
  }

  return (
    <main className="shell seller-shell">
      <header className="seller-dashboard-header">
        <div>
          <p className="eyebrow">Área do vendedor</p>
          <h1>Seus anúncios.</h1>
          <p className="lede">Perfil, anúncios e contatos são carregados pelas APIs autenticadas do BPT2. Ownership e normalização continuam no backend.</p>
        </div>
        {user ? <button className="secondary-action" type="button" onClick={signOut}>Sair</button> : null}
      </header>

      {loading ? <p className="seller-shell-status">Verificando sessão…</p> : null}
      {error ? <p className="seller-auth-error">{error}</p> : null}
      {notice ? <p className="seller-auth-notice">{notice}</p> : null}

      {!loading && !user ? (
        <section className="seller-auth-card" aria-live="polite">
          <h2>Entrar como vendedor</h2>
          <p>A senha é informada somente no Auth Server. Este cliente usa Authorization Code + PKCE.</p>
          <button className="primary-action" type="button" onClick={signIn}>Entrar</button>
        </section>
      ) : null}

      {!loading && user ? (
        <div className="seller-dashboard-grid">
          <section className="seller-panel">
            <div className="seller-panel-heading"><div><p className="eyebrow">Perfil</p><h2>{profile ? "Dados públicos" : "Complete seu perfil"}</h2></div></div>
            <form className="seller-profile-form" onSubmit={saveProfile}>
              <label>Nome de exibição<input name="displayName" value={displayName} onChange={(event) => setDisplayName(event.target.value)} required autoComplete="organization" /></label>
              <label>WhatsApp com código do país<input name="whatsAppNumber" value={whatsAppNumber} onChange={(event) => setWhatsAppNumber(event.target.value)} required inputMode="tel" autoComplete="tel" placeholder="+55 (11) 99999-8877" /></label>
              <p className="seller-form-help">Formatação é aceita na entrada; o backend devolve e persiste o número canônico somente com dígitos.</p>
              <button className="primary-action" type="submit" disabled={savingProfile}>{savingProfile ? "Salvando…" : "Salvar perfil"}</button>
            </form>
          </section>

          <section className="seller-panel seller-listings-panel">
            <div className="seller-panel-heading"><div><p className="eyebrow">Marketplace</p><h2>Meus anúncios</h2></div><div className="seller-panel-actions"><span className="seller-count">{listings.length}</span><Link className="primary-action action-link" href="/vender/anuncios/novo">Novo anúncio</Link></div></div>
            {listings.length === 0 ? <div className="empty-state seller-empty-state"><h3>Nenhum anúncio ainda.</h3><p>Crie um Draft escolhendo um Vehicle do catálogo canônico.</p></div> : (
              <div className="seller-listing-list">{listings.map((listing) => <article className="seller-listing-row" key={listing.id}><div><p className="seller-listing-status">{listing.status}</p><h3>{listing.title}</h3><p className="seller-listing-location">{listing.city} / {listing.stateCode}</p></div><div className="seller-listing-actions"><p className="seller-listing-price">{formatPrice(listing.price)}</p><Link className="secondary-action action-link" href={`/vender/anuncios/${listing.id}`}>Editar</Link></div></article>)}</div>
            )}
          </section>

          <section className="seller-panel seller-listings-panel">
            <div className="seller-panel-heading"><div><p className="eyebrow">Contatos</p><h2>Leads de WhatsApp</h2></div><span className="seller-count">{leads.length}</span></div>
            {leads.length === 0 ? <div className="empty-state seller-empty-state"><h3>Nenhum contato ainda.</h3><p>Quando alguém iniciar um contato pelo WhatsApp de um anúncio seu, ele aparecerá aqui.</p></div> : (
              <div className="seller-listing-list">
                {leads.map((lead) => (
                  <article className="seller-listing-row" key={lead.id}>
                    <div>
                      <p className="seller-listing-status">{leadStatusLabel(lead)} · {lead.channel}</p>
                      <h3>{lead.listingTitle}</h3>
                      <p className="seller-listing-location">Recebido em {new Date(lead.createdAtUtc).toLocaleString("pt-BR")}</p>
                      {lead.contactedAtUtc ? <p className="seller-form-help">Atendido em {new Date(lead.contactedAtUtc).toLocaleString("pt-BR")}</p> : null}
                      {lead.closedAtUtc ? <p className="seller-form-help">Encerrado em {new Date(lead.closedAtUtc).toLocaleString("pt-BR")}</p> : null}
                    </div>
                    <div className="seller-listing-actions">
                      <p className="seller-form-help">{lead.buyerUserId ? "Buyer autenticado" : "Contato anônimo"}</p>
                      {!lead.closedAtUtc && !lead.contactedAtUtc ? <button className="primary-action" type="button" disabled={updatingLeadId === lead.id} onClick={() => void markLeadContacted(lead.id)}>{updatingLeadId === lead.id ? "Atualizando…" : "Marcar como atendido"}</button> : null}
                      {!lead.closedAtUtc ? <button className="primary-action" type="button" disabled={updatingLeadId === lead.id} onClick={() => void closeLead(lead.id, "Won")}>{updatingLeadId === lead.id ? "Atualizando…" : "Marcar como vendido"}</button> : null}
                      {!lead.closedAtUtc ? <button className="secondary-action" type="button" disabled={updatingLeadId === lead.id} onClick={() => void closeLead(lead.id, "Lost")}>{updatingLeadId === lead.id ? "Atualizando…" : "Encerrar sem venda"}</button> : null}
                      <Link className="secondary-action action-link" href={`/vender/anuncios/${lead.listingId}`}>Ver anúncio</Link>
                    </div>
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
