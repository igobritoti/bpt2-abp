"use client";

import { useEffect, useState } from "react";
import type { User } from "oidc-client-ts";

import { getCurrentSellerUser, getSellerUserManager } from "../../lib/seller-auth";

export default function SellerEntryPage() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getCurrentSellerUser()
      .then(setUser)
      .catch((reason: unknown) => {
        setError(reason instanceof Error ? reason.message : "Não foi possível ler a sessão Seller.");
      })
      .finally(() => setLoading(false));
  }, []);

  async function signIn() {
    setError(null);
    await getSellerUserManager().signinRedirect();
  }

  async function signOut() {
    setError(null);
    await getSellerUserManager().signoutRedirect();
  }

  return (
    <main className="shell seller-shell">
      <p className="eyebrow">Área do vendedor</p>
      <h1>Venda seu veículo.</h1>
      <p className="lede">
        Este é o primeiro boundary autenticado do Seller. O login é delegado ao Auth Server do BPT2 por OpenID Connect com Authorization Code + PKCE.
      </p>

      <section className="seller-auth-card" aria-live="polite">
        {loading ? <p>Verificando sessão…</p> : null}
        {error ? <p className="seller-auth-error">{error}</p> : null}

        {!loading && !user ? (
          <>
            <h2>Entrar como vendedor</h2>
            <p>A senha é informada somente no Auth Server. O public web não recebe nem armazena a credencial.</p>
            <button className="primary-action" type="button" onClick={signIn}>
              Entrar
            </button>
          </>
        ) : null}

        {!loading && user ? (
          <>
            <h2>Sessão autenticada</h2>
            <p>{user.profile.name ?? user.profile.preferred_username ?? user.profile.sub}</p>
            <button className="secondary-action" type="button" onClick={signOut}>
              Sair
            </button>
          </>
        ) : null}
      </section>
    </main>
  );
}
