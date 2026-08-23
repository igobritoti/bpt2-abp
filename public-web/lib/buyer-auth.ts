import { UserManager, WebStorageStateStore, type User } from "oidc-client-ts";

let buyerUserManager: UserManager | undefined;

function getBrowserOrigin(): string {
  if (typeof window === "undefined") {
    throw new Error("Buyer authentication is only available in the browser.");
  }
  return window.location.origin;
}

export function getBuyerUserManager(): UserManager {
  if (buyerUserManager) {
    return buyerUserManager;
  }

  const origin = getBrowserOrigin();
  const authority =
    process.env.NEXT_PUBLIC_BPT_AUTHORITY ??
    process.env.NEXT_PUBLIC_BPT_API_BASE_URL ??
    "http://127.0.0.1:5093";
  const clientId = process.env.NEXT_PUBLIC_BPT_BUYER_CLIENT_ID ?? "BomPraTi_BuyerWeb";
  const stateStore = new WebStorageStateStore({ store: window.sessionStorage });

  buyerUserManager = new UserManager({
    authority,
    client_id: clientId,
    redirect_uri: `${origin}/favoritos/callback`,
    post_logout_redirect_uri: `${origin}/favoritos`,
    response_type: "code",
    scope: "openid profile email roles BomPraTi",
    loadUserInfo: false,
    automaticSilentRenew: false,
    userStore: stateStore,
    stateStore,
  });

  return buyerUserManager;
}

export async function getCurrentBuyerUser(): Promise<User | null> {
  const user = await getBuyerUserManager().getUser();
  return user && !user.expired ? user : null;
}

export async function signInBuyer(returnTo = "/favoritos") {
  await getBuyerUserManager().signinRedirect({ state: { returnTo } });
}
