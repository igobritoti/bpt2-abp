import type { MetadataRoute } from "next";
import { getPublicListings } from "@/lib/public-listings";
import { publicUrl } from "@/lib/site-url";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 100;

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const entries: MetadataRoute.Sitemap = [
    {
      url: publicUrl("/"),
      changeFrequency: "daily",
      priority: 1,
    },
  ];

  let skip = 0;
  while (true) {
    const page = await getPublicListings({ skip, take: PAGE_SIZE });

    for (const listing of page.items) {
      entries.push({
        url: publicUrl(`/anuncios/${listing.id}`),
        changeFrequency: "daily",
        priority: 0.8,
      });
    }

    if (page.items.length === 0 || skip + page.items.length >= page.totalCount) {
      break;
    }

    skip += page.items.length;
  }

  return entries;
}
