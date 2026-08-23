import { UserManager, WebStorageStateStore, type User } from "oidc-client-ts";

let sellerUserManager: UserManager | undefined;

function getBrowserOrigin(): string {
  if (typeof window === "undefined") {
    throw new Error("Seller authentication is only available in the browser.");
  }

  return window.location.origin;
}

export function getSellerUserManager(): UserManager {
  if (sellerUserManager) {
    return sellerUserManager;
  }

  const origin = getBrowserOrigin();
  const authority =
    process.env.NEXT_PUBLIC_BPT_AUTHORITY ??
    process.env.NEXT_PUBLIC_BPT_API_BASE_URL ??
    "http://127.0.0.1:5093";
  const clientId = process.env.NEXT_PUBLIC_BPT_SELLER_CLIENT_ID ?? "BomPraTi_SellerWeb";
  const stateStore = new WebStorageStateStore({ store: window.sessionStorage });

  sellerUserManager = new UserManager({
    authority,
    client_id: clientId,
    redirect_uri: `${origin}/vender/callback`,
    post_logout_redirect_uri: `${origin}/vender`,
    response_type: "code",
    scope: "openid profile email roles BomPraTi",
    loadUserInfo: false,
    automaticSilentRenew: false,
    userStore: stateStore,
    stateStore,
  });

  return sellerUserManager;
}

export async function getCurrentSellerUser(): Promise<User | null> {
  const user = await getSellerUserManager().getUser();
  return user && !user.expired ? user : null;
}
