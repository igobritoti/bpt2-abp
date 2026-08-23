import { UserManager, WebStorageStateStore, type User } from "oidc-client-ts";

const DEFAULT_AUTHORITY = "http://127.0.0.1:5093";
const DEFAULT_CLIENT_ID = "BomPraTi_SellerWeb";
const SELLER_SCOPE = "openid profile email roles BomPraTi";

let sellerAuthManager: UserManager | null = null;

function trimTrailingSlash(value: string): string {
  return value.replace(/\/+$/, "");
}

export function getSellerAuthManager(): UserManager {
  if (typeof window === "undefined") {
    throw new Error("Seller authentication is only available in the browser.");
  }

  if (sellerAuthManager) {
    return sellerAuthManager;
  }

  const authority = trimTrailingSlash(
    process.env.NEXT_PUBLIC_BPT_AUTHORITY ??
      process.env.NEXT_PUBLIC_BPT_API_BASE_URL ??
      DEFAULT_AUTHORITY,
  );
  const clientId = process.env.NEXT_PUBLIC_BPT_SELLER_CLIENT_ID ?? DEFAULT_CLIENT_ID;
  const origin = window.location.origin;
  const storage = new WebStorageStateStore({ store: window.sessionStorage });

  sellerAuthManager = new UserManager({
    authority,
    client_id: clientId,
    redirect_uri: `${origin}/auth/callback`,
    post_logout_redirect_uri: `${origin}/auth/logout-callback`,
    response_type: "code",
    scope: SELLER_SCOPE,
    loadUserInfo: false,
    automaticSilentRenew: false,
    monitorSession: false,
    stateStore: storage,
    userStore: storage,
  });

  return sellerAuthManager;
}

export async function getCurrentSellerUser(): Promise<User | null> {
  const user = await getSellerAuthManager().getUser();
  if (!user || user.expired) {
    return null;
  }

  return user;
}
