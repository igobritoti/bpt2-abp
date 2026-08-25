using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BomPraTi.Catalog.Data.Migrations
{
    public partial class InitialCatalog : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "CatalogBrands",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    NormalizedName = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    ExtraProperties = table.Column<string>(type: "text", nullable: false),
                    ConcurrencyStamp = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false)
                },
                constraints: table => table.PrimaryKey("PK_CatalogBrands", x => x.Id));

            migrationBuilder.CreateTable(
                name: "CatalogGenerations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ModelId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    StartYear = table.Column<int>(type: "integer", nullable: true),
                    EndYear = table.Column<int>(type: "integer", nullable: true),
                    ExtraProperties = table.Column<string>(type: "text", nullable: false),
                    ConcurrencyStamp = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false)
                },
                constraints: table => table.PrimaryKey("PK_CatalogGenerations", x => x.Id));

            migrationBuilder.CreateTable(
                name: "CatalogModels",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BrandId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    NormalizedName = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    ExtraProperties = table.Column<string>(type: "text", nullable: false),
                    ConcurrencyStamp = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false)
                },
                constraints: table => table.PrimaryKey("PK_CatalogModels", x => x.Id));

            migrationBuilder.CreateTable(
                name: "CatalogVehicles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    BrandId = table.Column<Guid>(type: "uuid", nullable: false),
                    ModelId = table.Column<Guid>(type: "uuid", nullable: false),
                    GenerationId = table.Column<Guid>(type: "uuid", nullable: true),
                    VersionId = table.Column<Guid>(type: "uuid", nullable: false),
                    ModelYear = table.Column<int>(type: "integer", nullable: true),
                    ExtraProperties = table.Column<string>(type: "text", nullable: false),
                    ConcurrencyStamp = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false)
                },
                constraints: table => table.PrimaryKey("PK_CatalogVehicles", x => x.Id));

            migrationBuilder.CreateTable(
                name: "CatalogVersions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ModelId = table.Column<Guid>(type: "uuid", nullable: false),
                    GenerationId = table.Column<Guid>(type: "uuid", nullable: true),
                    Name = table.Column<string>(type: "character varying(180)", maxLength: 180, nullable: false),
                    NormalizedName = table.Column<string>(type: "character varying(180)", maxLength: 180, nullable: false),
                    ExtraProperties = table.Column<string>(type: "text", nullable: false),
                    ConcurrencyStamp = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false)
                },
                constraints: table => table.PrimaryKey("PK_CatalogVersions", x => x.Id));

            migrationBuilder.CreateIndex("IX_CatalogBrands_NormalizedName", "CatalogBrands", "NormalizedName", unique: true);
            migrationBuilder.CreateIndex("IX_CatalogGenerations_ModelId_Name", "CatalogGenerations", new[] { "ModelId", "Name" });
            migrationBuilder.CreateIndex("IX_CatalogModels_BrandId_NormalizedName", "CatalogModels", new[] { "BrandId", "NormalizedName" }, unique: true);
            migrationBuilder.CreateIndex("IX_CatalogVehicles_BrandId_ModelId_GenerationId_VersionId_ModelYear", "CatalogVehicles", new[] { "BrandId", "ModelId", "GenerationId", "VersionId", "ModelYear" }, unique: true);
            migrationBuilder.CreateIndex("IX_CatalogVersions_ModelId_GenerationId_NormalizedName", "CatalogVersions", new[] { "ModelId", "GenerationId", "NormalizedName" }, unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable("CatalogBrands");
            migrationBuilder.DropTable("CatalogGenerations");
            migrationBuilder.DropTable("CatalogModels");
            migrationBuilder.DropTable("CatalogVehicles");
            migrationBuilder.DropTable("CatalogVersions");
        }
    }
}
