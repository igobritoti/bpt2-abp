const LOCAL_FALLBACK = "http://127.0.0.1:3000";

export function publicSiteUrl(): URL {
  const configured = process.env.BPT_PUBLIC_BASE_URL?.trim();

  if (!configured) {
    if (process.env.NODE_ENV === "production" && process.env.CI !== "true") {
      throw new Error("BPT_PUBLIC_BASE_URL is required in production.");
    }

    return new URL(LOCAL_FALLBACK);
  }

  const url = new URL(configured);
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error("BPT_PUBLIC_BASE_URL must use http or https.");
  }

  url.pathname = "/";
  url.search = "";
  url.hash = "";
  return url;
}

export function publicUrl(path: string): string {
  return new URL(path.replace(/^\/+/, ""), publicSiteUrl()).toString();
}
