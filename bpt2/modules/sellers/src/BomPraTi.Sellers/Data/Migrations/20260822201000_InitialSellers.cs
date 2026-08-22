using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BomPraTi.Sellers.Data.Migrations;

[DbContext(typeof(SellersDbContext))]
[Migration("20260822201000_InitialSellers")]
public partial class InitialSellers : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "SellerProfiles",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                DisplayName = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                WhatsAppNumber = table.Column<string>(type: "character varying(15)", maxLength: 15, nullable: false),
                ExtraProperties = table.Column<string>(type: "text", nullable: false),
                ConcurrencyStamp = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false)
            },
            constraints: table => table.PrimaryKey("PK_SellerProfiles", x => x.Id));
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable("SellerProfiles");
    }
}
