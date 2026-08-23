"use client";

import { useEffect, useState } from "react";
import { getSellerAuthManager } from "../../../lib/seller-auth";

export default function SellerLogoutCallbackPage() {
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    getSellerAuthManager()
      .signoutRedirectCallback()
      .then(() => {
        window.location.replace("/vender");
      })
      .catch((reason: unknown) => {
        setError(reason instanceof Error ? reason.message : "Falha ao concluir logout.");
      });
  }, []);

  return (
    <main style={{ maxWidth: 680, margin: "0 auto", padding: "64px 24px" }}>
      <h1>Saindo</h1>
      {error ? <p role="alert">{error}</p> : <p>Encerrando a sessão do vendedor…</p>}
    </main>
  );
}
