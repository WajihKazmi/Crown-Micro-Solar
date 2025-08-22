# API Diagnostics & Next Integration Steps

This file is a running scratchpad for the automated diagnostics work so the assistant can resume contextually in the next turn.

## Scope Added (Diagnostics Script `tool/api_diagnostics.dart`)
The diagnostics now logs (single-line JSON lines prefixed with `DIAG:`) for:
- Login (user / installer)
- Plant inventory (plants, devices, collectors)
- Sample device selection (first device for now)
- Key parameter one-day queries (LOAD_POWER, GRID_POWER, PV_OUTPUT_POWER, BATTERY_SOC) with candidate fallback resolution
- Device one-day paging columns (queryDeviceDataOneDayPaging) with title / row counts & latest column value extraction for power-related columns
- SP Device key parameter Month-Per-Day (querySPDeviceKeyParameterMonthPerDay) for ENERGY_TODAY, PV_OUTPUT_POWER
- SP Device key parameter Year-Per-Month (querySPDeviceKeyParameterYearPerMonth) for ENERGY_TODAY, PV_OUTPUT_POWER
- SP Device key parameter Total-Per-Year (querySPDeviceKeyParameterTotalPerYear) for ENERGY_TODAY, PV_OUTPUT_POWER
- Plant energy Month-Per-Day (queryPlantEnergyMonthPerDay)
- Plant energy Year-Per-Month (queryPlantEnergyYearPerMonth)
- (Earlier) Device live signal (queryDeviceCtrlField) — retained

## Why These Endpoints
They represent the old app's chart/data aggregation surfaces:
1. Realtime / latest (live signal / key parameter one day last point) -> current power / SOC cards
2. Intraday chart (paging or key parameter one-day) -> line chart (device detail / overview)
3. Daily aggregation (Month-Per-Day) -> bar chart / historical screen (future)
4. Monthly aggregation (Year-Per-Month) -> trends
5. Annual cumulative (Total-Per-Year) -> long-term summary
6. Plant level parallels for overview metrics

## Next Mapping Tasks (Planned)
1. Parse latest DIAG lines: build an internal map from logicalMetric -> {sourceEndpoint, apiParamUsed, sampleLatestValue} for both success & empty.
2. Enhance `DeviceRepository` to introduce a structured strategy object per logical metric:
   - priority list: [keyParamOneDay, pagingColumnMatch, liveSignalField]
   - aggregator for month/year/total to feed future history tabs
3. Implement caching layer (memory) for month/year responses to avoid repeated network on metric toggle.
4. Introduce `HistoricalDataViewModel` (if not present) to unify fetching month/year data (defer if out-of-scope for immediate fix of zero values).
5. Update summary card mapping:
   - Output Power: prefer keyParamOneDay PV_OUTPUT_POWER -> else paging 'Output Power'
   - Load Power (if device supports load): keyParamOneDay LOAD_POWER -> paging 'Load Power'
   - Grid Power: keyParamOneDay GRID_POWER -> net import/export logic if both available later
   - Battery SOC: keyParamOneDay BATTERY_SOC -> live signal fallback where available
6. Hide cards where all strategies return null after attempts (instead of showing 0).
7. Graph data source unification:
   - For intraday: if keyParamOneDay returns > 0 points use it; else use paging column extraction time series.
8. Add unit mapping (kW, kWh, %, etc.) derived from endpoint metadata (title.unit or parameter descriptor) and surface on UI.
9. Add lightweight test harness (new file under `test/`) that consumes a captured DIAG transcript and asserts parsing logic produces expected strategy decisions.
10. Provide an opt-in environment flag to print chosen data source per metric (debug overlay or console).

## Immediate Next Actions (Upcoming Turn)
 - DONE: Run diagnostics after latest changes and capture output.
 - DONE: Implement parser utility in `tool/parse_diagnostics.dart` to collate DIAG lines into summary JSON.
 - DONE: Add `MetricResolutionResult` + `resolveMetricOneDay` in `device_repository.dart` (non-breaking, backend only).
 - NEXT: Wire `resolveMetricOneDay` into the view model(s) powering summary cards & device graph.
 - NEXT: Insert a lightweight adapter that requests metrics in parallel then builds UI DTO.
 - NEXT: Add unit inference (phase after wiring) using paging titles' unit field when available.

## Assumptions / Open Questions
- Installer account currently failing login; need to confirm credentials or skip.

## Progress Delta (This Commit)
 - Extended diagnostics script with all-plants + plant + device quintet endpoints.
 - Added structured metric resolution backend (no UI changes yet).
 - Added DIAG parser utility for offline summarization.
 - Updated README with current state so assistant can resume.

## Immediate Wiring Plan
1. Create a `MetricAggregatorViewModel` (or extend existing device/overview VM) that calls `resolveMetricOneDay` for a set of logical metrics according to device capabilities.
2. Expose a `Map<String, MetricResolutionResult>` to UI; summary cards subscribe and render values or hide if `source == 'unsupported'` or no data.
3. For chart: request the chosen logical currently selected in dropdown -> if source key_param_one_day and we have raw series (later), else fetch paging and reconstruct a simple (timestamp,value) list.
4. Defer series hydration until after UI shows non-zero single values (solves immediate UX issue).
- Some endpoints consistently empty — may require different parameter tokens for certain device types; need real device variety to refine.
- Net/grid power sign semantics not yet defined (import vs export). Pending product decision.

## How To Re-run Diagnostics
```
flutter pub run tool/api_diagnostics.dart > diag.log
```
Then filter JSON lines:
```
select-string -Path diag.log -Pattern 'DIAG:' | ForEach-Object { $_.Line }
```

## Do Not Commit Secrets
The script holds temporary credentials; before production, externalize via env vars / secure storage.

## Ready For Next Step
Proceed with parser + repository refactor next.
