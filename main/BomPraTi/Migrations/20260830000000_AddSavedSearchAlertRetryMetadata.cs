using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BomPraTi.Migrations;

public partial class AddSavedSearchAlertRetryMetadata : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex(
            name: "IX_MarketplaceSavedSearchAlertDetectionRequests_ProcessedAtUtc_EnqueuedAtUtc",
            table: "MarketplaceSavedSearchAlertDetectionRequests");

        migrationBuilder.AddColumn<DateTime>(
            name: "LastAttemptAtUtc",
            table: "MarketplaceSavedSearchAlertDetectionRequests",
            type: "timestamp with time zone",
            nullable: true);

        migrationBuilder.AddColumn<DateTime>(
            name: "NextAttemptAtUtc",
            table: "MarketplaceSavedSearchAlertDetectionRequests",
            type: "timestamp with time zone",
            nullable: true);

        migrationBuilder.CreateIndex(
            name: "IX_MarketplaceSavedSearchAlertDetectionRequests_ProcessedAtUtc_NextAttemptAtUtc_EnqueuedAtUtc",
            table: "MarketplaceSavedSearchAlertDetectionRequests",
            columns: new[] { "ProcessedAtUtc", "NextAttemptAtUtc", "EnqueuedAtUtc" });
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex(
            name: "IX_MarketplaceSavedSearchAlertDetectionRequests_ProcessedAtUtc_NextAttemptAtUtc_EnqueuedAtUtc",
            table: "MarketplaceSavedSearchAlertDetectionRequests");

        migrationBuilder.DropColumn(
            name: "LastAttemptAtUtc",
            table: "MarketplaceSavedSearchAlertDetectionRequests");

        migrationBuilder.DropColumn(
            name: "NextAttemptAtUtc",
            table: "MarketplaceSavedSearchAlertDetectionRequests");

        migrationBuilder.CreateIndex(
            name: "IX_MarketplaceSavedSearchAlertDetectionRequests_ProcessedAtUtc_EnqueuedAtUtc",
            table: "MarketplaceSavedSearchAlertDetectionRequests",
            columns: new[] { "ProcessedAtUtc", "EnqueuedAtUtc" });
    }
}
