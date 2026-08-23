"use client";

import { useEffect, useState } from "react";
import type { User } from "oidc-client-ts";
import { getCurrentSellerUser, getSellerAuthManager } from "../../lib/seller-auth";

type SellerAuthState =
  | { status: "loading" }
  | { status: "anonymous" }
  | { status: "authenticated"; user: User }
  | { status: "error"; message: string };

export default function SellerEntryPage() {
  const [state, setState] = useState<SellerAuthState>({ status: "loading" });

  useEffect(() => {
    let active = true;

    getCurrentSellerUser()
      .then((user) => {
        if (!active) return;
        setState(user ? { status: "authenticated", user } : { status: "anonymous" });
      })
      .catch((error: unknown) => {
        if (!active) return;
        setState({ status: "error", message: error instanceof Error ? error.message : "Falha ao ler a sessão." });
      });

    return () => {
      active = false;
    };
  }, []);

  async function signIn() {
    await getSellerAuthManager().signinRedirect({ state: { returnTo: "/vender" } });
  }

  async function signOut() {
    await getSellerAuthManager().signoutRedirect();
  }

  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "64px 24px" }}>
      <p style={{ marginBottom: 8 }}>Área do vendedor</p>
      <h1 style={{ marginTop: 0 }}>Bom Pra Ti Seller</h1>
      <p>
        Este shell usa Authorization Code + PKCE contra o Auth Server BPT2. A senha é digitada somente no
        servidor de identidade; o public web não recebe nem armazena credenciais do vendedor.
      </p>

      {state.status === "loading" && <p>Verificando sessão…</p>}

      {state.status === "anonymous" && (
        <button type="button" onClick={signIn}>
          Entrar como vendedor
        </button>
      )}

      {state.status === "authenticated" && (
        <section>
          <p>
            Sessão autenticada como <strong>{state.user.profile.preferred_username ?? state.user.profile.sub}</strong>.
          </p>
          <button type="button" onClick={signOut}>
            Sair
          </button>
        </section>
      )}

      {state.status === "error" && <p role="alert">{state.message}</p>}
    </main>
  );
}
