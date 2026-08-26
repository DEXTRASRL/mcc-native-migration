// codeunit 60166 "DXR MCC Bellon SPOldGenBridge"
// {
//     // Native local migration for registry concept BELLON-P2 seq135 ("Sales/Purchase
//     // old-generation bridge copy"), whose Dispatcher Codeunit ID this codeunit replaces (was
//     // 60146, a placeholder shared with the whole BELLON-P2 batch; now its own dedicated object).
//     // Object name shortened from the requested "DXR MCC Bellon SalesPurchOldGen" (32 chars) to fit
//     // AL's 30-character object identifier limit (AL0305).
//     //
//     // Real source: "Bellon Upgrade Process" (59221) -> internal procedure
//     // MigrateAllSalesPurchOldGenBridge(), which calls 14 local per-table procedures
//     // (MigrateTableExt_SalesHeaderOldGenBridge, _SalesInvoiceHeaderOldGenBridge,
//     // _SalesCrMemoHeaderOldGenBridge, _SalesShipmentHeaderOldGenBridge, _SalesLineOldGenBridge,
//     // _SalesInvoiceLineOldGenBridge, _SalesHeaderArchiveOldGenBridge, _SalesLineArchiveOldGenBridge,
//     // _PurchaseHeaderOldGenBridge, _PurchInvHeaderOldGenBridge, _PurchRcptHeaderOldGenBridge,
//     // _PurchaseHeaderArchiveOldGenBridge, _PurchaseLineOldGenBridge, _PurchRcptLineOldGenBridge),
//     // each copying a "_BE_DXR" source field (50022-50037 per table) to a colliding "_Old"
//     // destination field (52787-52803 per table) via RecRef.Field()/CopyFieldIfExists.
//     //
//     // CONFIRMED NO-OP - do not port the 14 per-table procedures. Verified directly against real
//     // source on 2026-08-24:
//     //   1) MigrateAllSalesPurchOldGenBridge() itself has an EMPTY body in the current source, with
//     //      an inline comment dated 2026-08-20: "both ends of this bridge (source '_BE_DXR' fields
//     //      and destination '_Old' fields) are now ObsoleteState = Removed - confirmed via git
//     //      history that migration/v28.3 has never merged into deploy/production, so neither side
//     //      ever held live tenant data. This procedure is now a deliberate no-op; the 14 per-table
//     //      bridge procedures below are kept, unused, as documentation of the original field
//     //      mapping."
//     //   2) Independently re-verified against the real tableextension source
//     //      (src/Extentions/tables/*.TableExt.al) for all 14 tables: every single "_BE_DXR" source
//     //      field (50022-50037 range) and every "_Old" destination field (52787-52803 range) across
//     //      all 14 tables carries ObsoleteState = Removed, each with an explicit ObsoleteReason
//     //      confirming no live tenant data ever existed at either ID (sampled Sales Header,
//     //      Purchase Header, Sales Line, Purch. Rcpt. Line, Sales Invoice Line directly; pattern is
//     //      exhaustive per procedure 2's own reasoning, not a partial state).
//     //   3) This exact conclusion is already independently documented THREE times elsewhere in this
//     //      same MCC codebase, reached by prior sessions before this one:
//     //      - "DXR MCC Bellon Migr Phase2" (60146) header comment: "13 of those procedures - the
//     //        whole Sales/Purchase Header family... were retroactively removed from the active call
//     //        list on 2026-08-20 and are dead code kept only as documentation... NOT ported here,
//     //        matching the source's own current behavior."
//     //      - "DXR MCC Bellon Migr Phase3" (60147) header comment: "MigrateAllSalesPurchOldGenBridge()
//     //        - CONFIRMED NO-OP in the current source... Not ported here - nothing to run."
//     //      - "DXR MCC Bellon Migr Phase10" (60154), the direct successor concept (BELLON-P10) for
//     //        this same 14-table "_Old" field family, is itself implemented as a pure UpgradeTag-only
//     //        no-op for the identical reason (100 "_Old" fields marked Removed).
//     //   Given both source and destination fields are ObsoleteState = Removed, a typed Record
//     //   reference to either field name would not compile (Removed fields are not accessible
//     //   symbols), and even a RecordRef-based CopyFieldIfExists port would be permanently inert at
//     //   runtime (RecordRef.FieldExist returns false for a removed field ID) - there is no data
//     //   anywhere to restore. Implemented here as a trivial UpgradeTag-gated no-op, mirroring Phase10's
//     //   exact pattern, so this registry concept (BELLON-P2 seq135) points at a real, dedicated,
//     //   compiling object instead of a placeholder shared with an unrelated batch's dispatcher ID.
//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-SalesPurchOldGenBridge') then
//             exit;

//         // No-op - see header comment. Both the "_BE_DXR" source fields and the "_Old" destination
//         // fields this bridge would have copied between are ObsoleteState = Removed in the real
//         // source, confirmed to have never held live tenant data on any published version.

//         UpgradeTag.SetUpgradeTag('DXR-SalesPurchOldGenBridge');
//     end;
// }
