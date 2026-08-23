"use client";

import { useEffect, useState } from "react";
import { getSellerAuthManager } from "../../../lib/seller-auth";

type CallbackState = { returnTo?: string };

export default function SellerAuthCallbackPage() {
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getSellerAuthManager()
      .signinRedirectCallback()
      .then((user) => {
        const state = user.state as CallbackState | undefined;
        const returnTo = state?.returnTo?.startsWith("/") ? state.returnTo : "/vender";
        window.location.replace(returnTo);
      })
      .catch((reason: unknown) => {
        setError(reason instanceof Error ? reason.message : "Falha ao concluir autenticação.");
      });
  }, []);

  return (
    <main style={{ maxWidth: 680, margin: "0 auto", padding: "64px 24px" }}>
      <h1>Concluindo autenticação</h1>
      {error ? <p role="alert">{error}</p> : <p>Validando o retorno seguro do Auth Server…</p>}
    </main>
  );
}
