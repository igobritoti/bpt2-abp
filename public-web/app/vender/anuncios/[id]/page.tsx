"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { FormEvent, useEffect, useState } from "react";
import type { User } from "oidc-client-ts";

import { getCurrentSellerUser } from "../../../../lib/seller-auth";
import {
  getMyListingDetail,
  getVehicle,
  type SellerListingDetail,
  type VehicleRef,
  updateSellerListing,
} from "../../../../lib/seller-api";

function optionalNumber(value: string): number | null {
  return value.trim() === "" ? null : Number(value);
}

function vehicleLabel(vehicle: VehicleRef | null): string {
  if (!vehicle) {
    return "Vehicle canônico indisponível";
  }
  return [vehicle.brand, vehicle.model, vehicle.version, vehicle.modelYear]
    .filter((value) => value !== null && value !== undefined && value !== "")
    .map(String)
    .join(" · ");
}

export default function EditSellerListingPage() {
  const params = useParams<{ id: string }>();
  const listingId = params.id;

  const [user, setUser] = useState<User | null>(null);
  const [detail, setDetail] = useState<SellerListingDetail | null>(null);
  const [vehicle, setVehicle] = useState<VehicleRef | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const [title, setTitle] = useState("");
  const [price, setPrice] = useState("");
  const [description, setDescription] = useState("");
  const [manufactureYear, setManufactureYear] = useState("");
  const [mileageKm, setMileageKm] = useState("");
  const [color, setColor] = useState("");
  const [city, setCity] = useState("");
  const [stateCode, setStateCode] = useState("");

  useEffect(() => {
    async function load() {
      try {
        const currentUser = await getCurrentSellerUser();
        setUser(currentUser);
        if (!currentUser) {
          return;
        }

        const currentDetail = await getMyListingDetail(currentUser.access_token, listingId);
        setDetail(currentDetail);
        if (!currentDetail) {
          return;
        }

        const listing = currentDetail.listing;
        setTitle(listing.title);
        setPrice(String(listing.price));
        setDescription(listing.description);
        setManufactureYear(listing.manufactureYear === null ? "" : String(listing.manufactureYear));
        setMileageKm(listing.mileageKm === null ? "" : String(listing.mileageKm));
        setColor(listing.color ?? "");
        setCity(listing.city);
        setStateCode(listing.stateCode);
        setVehicle(await getVehicle(listing.vehicleId));
      } catch (reason: unknown) {
        setError(reason instanceof Error ? reason.message : "Não foi possível abrir este anúncio.");
      } finally {
        setLoading(false);
      }
    }

    void load();
  }, [listingId]);

  async function save(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!user || !detail) {
      return;
    }

    setError(null);
    setNotice(null);
    setSaving(true);
    try {
      const saved = await updateSellerListing(user.access_token, listingId, {
        title,
        price: Number(price),
        concurrencyStamp: detail.listing.concurrencyStamp,
        description,
        manufactureYear: optionalNumber(manufactureYear),
        mileageKm: optionalNumber(mileageKm),
        color: color.trim() || null,
        city,
        stateCode,
      });
      setDetail({ ...detail, listing: saved });
      setNotice("Anúncio salvo. O novo ConcurrencyStamp devolvido pelo backend já está ativo nesta edição.");
    } catch (reason: unknown) {
      setError(reason instanceof Error ? reason.message : "Não foi possível salvar o anúncio.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="shell seller-shell seller-editor-shell">
      <header className="seller-dashboard-header">
        <div>
          <p className="eyebrow">Área do vendedor</p>
          <h1>Editar anúncio.</h1>
          <p className="lede">
            Esta tela só abre Listings pertencentes à sessão atual. A gravação usa concorrência otimista do backend.
          </p>
        </div>
        <Link className="secondary-action action-link" href="/vender">
          Meus anúncios
        </Link>
      </header>

      {loading ? <p className="seller-shell-status">Carregando anúncio…</p> : null}
      {error ? <p className="seller-auth-error">{error}</p> : null}
      {notice ? <p className="seller-auth-notice">{notice}</p> : null}

      {!loading && !user ? (
        <section className="seller-auth-card">
          <h2>Sessão necessária</h2>
          <p>Entre pela área do vendedor antes de editar um anúncio.</p>
          <Link className="primary-action action-link" href="/vender">
            Ir para login
          </Link>
        </section>
      ) : null}

      {!loading && user && !detail ? (
        <section className="seller-auth-card">
          <h2>Anúncio não disponível</h2>
          <p>Este Listing não pertence ao Seller autenticado ou não existe.</p>
          <Link className="secondary-action action-link" href="/vender">
            Voltar
          </Link>
        </section>
      ) : null}

      {!loading && user && detail ? (
        <section className="seller-panel seller-editor-panel">
          <div className="seller-edit-summary">
            <div>
              <p className="eyebrow">{detail.listing.status}</p>
              <h2>{vehicleLabel(vehicle)}</h2>
            </div>
            <p>{detail.photos.length} foto(s) na galeria atual</p>
          </div>

          <form className="seller-profile-form seller-listing-form" onSubmit={save}>
            <label>
              Título
              <input value={title} onChange={(event) => setTitle(event.target.value)} required />
            </label>

            <label>
              Preço
              <input type="number" min="0" step="0.01" value={price} onChange={(event) => setPrice(event.target.value)} required />
            </label>

            <label>
              Descrição
              <textarea value={description} onChange={(event) => setDescription(event.target.value)} required rows={7} />
            </label>

            <div className="seller-form-grid">
              <label>
                Ano de fabricação
                <input type="number" value={manufactureYear} onChange={(event) => setManufactureYear(event.target.value)} />
              </label>
              <label>
                Quilometragem
                <input type="number" min="0" value={mileageKm} onChange={(event) => setMileageKm(event.target.value)} />
              </label>
              <label>
                Cor
                <input value={color} onChange={(event) => setColor(event.target.value)} />
              </label>
              <label>
                Cidade
                <input value={city} onChange={(event) => setCity(event.target.value)} required />
              </label>
              <label>
                UF
                <input value={stateCode} onChange={(event) => setStateCode(event.target.value)} required />
              </label>
            </div>

            <p className="seller-form-help">
              Vehicle e ownership não são escolhidos nesta edição. Um conflito 409 interrompe o save em vez de sobrescrever uma versão mais nova.
            </p>

            <button className="primary-action" type="submit" disabled={saving}>
              {saving ? "Salvando…" : "Salvar alterações"}
            </button>
          </form>
        </section>
      ) : null}
    </main>
  );
}
