# Backend — Broker Apps (v2, supersedes the previous version)

## What changed since v1

**11 of the 20 `package_name` values in v1 were wrong.** They do not exist on
the Google Play Store. We have since verified all 20 against live Play Store
listings and corrected them in the app.

The backend is currently returning the **old, incorrect** values from
`GET /api/trading-apps`, so those 11 rows need updating. Section 1 has the
corrected table.

Nothing else about the contract changes. The `broking_app` values are unchanged
and already agreed.

---

## 1. `GET /api/trading-apps` — package names must be corrected

### Why this matters

The app blocks and launches a broker by its Android package id.

- A wrong `package_name` means the app **blocks nothing**, and when the user
  taps "Open Trading App" it sends them to a Play Store page that does not
  exist.
- The app also merges API rows with its own bundled list **by package id**. If
  the backend returns a different id than the app bundles, the user sees **two
  tiles for the same broker**.

### The 11 rows to correct

| Broker | Old `package_name` (wrong) | New `package_name` (correct) | Play Store listing |
| --- | --- | --- | --- |
| ICICI Direct | `com.icicidirect.mobile` | `com.icicidirect.idirectsuper` | ICICI Direct-Stocks F&O MF IPO |
| HDFC Securities | `com.hdfcsec.trade` | `com.hsl.investright` | HDFC Securities InvestRight |
| SBI Securities | `com.sbi.smart` | `com.msf.sbicap.securities` | SBI Securities: Stocks & SIP |
| Dhan | `co.dhan` | `com.dhan.live` | Dhan: Stock Market Trading App |
| Motilal Oswal | `com.motilaloswal.moinvestor` | `com.mosl.mobile` | MO RIISE: Stocks, IPO & Demat |
| Sharekhan | `com.sharekhan` | `com.sharekhan.androidsharemobile` | Mirae Asset Sharekhan: Stocks |
| Axis Securities | `com.axis.direct` | `com.axisdirect.invest` | Axis Direct Investor |
| Choice | `com.choicebroking.jiffy` | `com.choiceequitybroking.jiffy` | FinX - Demat, Stock, FnO & IPO |
| Geojit | `com.geojit.selfie` | `com.geojit.flip_mobile` | Geojit Flip-Demat, Stocks, IPO |
| Mirae Asset | `com.mshare` | `com.rs.mirae` | mStock: Demat & Stock Trading |
| Sahi | `com.sahi.app` | `com.aaritya.sahi_trade_app` | SAHI : Options & Stock Trading |

The other 9 were already correct and need no change: Groww, Zerodha, Angel One,
Upstox, Kotak Neo, Paytm Money, INDmoney, IIFL Securities, 5paisa.

### Full list after correction — all 20

| # | `name` | `package_name` |
| --- | --- | --- |
| 1 | Groww | `com.nextbillion.groww` |
| 2 | Zerodha | `com.zerodha.kite3` |
| 3 | Angel One | `com.msf.angelmobile` |
| 4 | ICICI Direct | `com.icicidirect.idirectsuper` |
| 5 | Upstox | `in.upstox.app` |
| 6 | Kotak Neo | `com.kotak.neo` |
| 7 | HDFC Securities | `com.hsl.investright` |
| 8 | SBI Securities | `com.msf.sbicap.securities` |
| 9 | Dhan | `com.dhan.live` |
| 10 | Motilal Oswal | `com.mosl.mobile` |
| 11 | Paytm Money | `com.paytmmoney` |
| 12 | INDmoney | `in.indwealth` |
| 13 | Sharekhan | `com.sharekhan.androidsharemobile` |
| 14 | Axis Securities | `com.axisdirect.invest` |
| 15 | IIFL Securities | `com.indiainfoline` |
| 16 | 5paisa | `com.fivepaisa.trade` |
| 17 | Choice | `com.choiceequitybroking.jiffy` |
| 18 | Geojit | `com.geojit.flip_mobile` |
| 19 | Mirae Asset | `com.rs.mirae` |
| 20 | Sahi | `com.aaritya.sahi_trade_app` |

Every id above returns HTTP 200 at
`https://play.google.com/store/apps/details?id=<package_name>`.
That is a quick way to check any id before adding it.

### Two choices we made — flag if you disagree

- **HDFC Securities** → `com.hsl.investright` (HDFC Securities InvestRight).
  Their newer app, **HDFC SKY** (`com.cloudtradetech.sky`), is a separate
  listing. We use InvestRight as the primary and try SKY as a fallback when
  launching. If most of your users are on SKY, tell us and we will swap them.
- **Axis Securities** → `com.axisdirect.invest` (Axis Direct Investor, the
  retail app). `com.axisdirect.orbit` is their trading terminal and is used
  only as a launch fallback.

### Response shape (unchanged)

```json
{
  "status": "ok",
  "payload": [
    {
      "id": "1",
      "name": "Groww",
      "package_name": "com.nextbillion.groww",
      "is_target": "1",
      "is_stoploss": "1",
      "is_gtt": "1",
      "created_at": "1794891931"
    }
  ]
}
```

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | string or int | Yes | Any stable identifier. |
| `name` | string | Yes | Display name, as in the table above. |
| `package_name` | string | Yes | **Android package id. Must match exactly.** |
| `is_target` | `"1"` / `"0"` | Yes | Broker app supports a target price field. |
| `is_stoploss` | `"1"` / `"0"` | Yes | Broker app supports a stop-loss field. |
| `is_gtt` | `"1"` / `"0"` | Yes | Broker app supports GTT orders. |
| `created_at` | string | No | Unix seconds. Unused by the app. |

`"1"`, `1`, `true` and `"true"` are all accepted for the boolean flags.

### cURL

```bash
curl --location '{{base_url}}/api/trading-apps'
```

### Adding brokers later

Any broker returned here that the app does not bundle is **appended to the
picker automatically**, with no app release needed. It renders with a generic
initial-letter logo until a designed logo ships in the app.

---

## 2. Still open: GTT flags

Staging currently returns:

| Broker | `is_target` / `is_stoploss` / `is_gtt` |
| --- | --- |
| Groww | 1 / 1 / 1 |
| Zerodha | 0 / 0 / 1 |
| Upstox | 0 / 0 / 1 |
| The other 17 | 0 / 0 / 0 |

These flags decide what the app asks the user for after a GTT hit:

```
is_gtt && is_target && is_stoploss  ->  extended form: trigger + SL + target
anything else                        ->  short form: trigger price only
```

With `0 / 0 / 0`, those 17 brokers get the short form. Please confirm that is
intended, or send the correct flags per broker.

---

## 3. Already settled — no action needed

### `POST /api/process/setup` → `broking_app`

Confirmed by backend: the column is a plain `VARCHAR` that stores exactly what
the app sends, with no validation or conversion. The app sends these 20 values:

| Broker | `broking_app` |
| --- | --- |
| Groww | `groww` |
| Zerodha | `zerodha` |
| Angel One | `angel_one` |
| ICICI Direct | `icici_direct` |
| Upstox | `upstox` |
| Kotak Neo | `kotak_neo` |
| HDFC Securities | `hdfc_securities` |
| SBI Securities | `sbi_securities` |
| Dhan | `dhan` |
| Motilal Oswal | `motilal_oswal` |
| Paytm Money | `paytm_money` |
| INDmoney | `indmoney` |
| Sharekhan | `sharekhan` |
| Axis Securities | `axis_securities` |
| IIFL Securities | `iifl_securities` |
| 5paisa | `5paisa` |
| Choice | `choice` |
| Geojit | `geojit` |
| Mirae Asset | `mirae_asset` |
| Sahi | `sahi` |

`zerodha` and `indmoney` stay as-is; the `zerodha_kite` / `ind_money` variants
are not used. These values are pinned by an automated test in the app, so they
cannot change silently.

`POST /api/process/update-broking-app` and `POST /api/process/edit` take the
same values.

### Existing users

Users who set up before this change have `broking_app` of `zerodha`, `upstox`
or `groww`. The app still produces those exact values, so **no migration is
needed**.

### Unaffected endpoints

`trade/executed`, `gtt/alert/create`, `app/state`, `app/force-unlock`,
`messages/get-by-user` and the coin APIs are all broker-agnostic.

---

## Checklist

- [ ] **Correct the 11 `package_name` values in `GET /api/trading-apps`** (section 1)
- [ ] Confirm the HDFC Securities and Axis Securities choices (section 1)
- [ ] Confirm or correct the `is_target` / `is_stoploss` / `is_gtt` flags (section 2)
- [x] `GET /api/trading-apps` returns all 20 rows — done
- [x] `broking_app` accepts all 20 values — `VARCHAR`, no validation
- [x] `indmoney` and `zerodha` confirmed — no change
