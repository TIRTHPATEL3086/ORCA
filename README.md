<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:1B1C18,55:4F46E5,100:C4BBF0&height=250&section=header&text=ORCA&fontSize=96&fontColor=ffffff&fontAlignY=38&desc=Voice-first%20%C2%B7%20Offline%20Marine%20Safety%20Copilot&descSize=22&descAlignY=60&animation=fadeIn" width="100%" alt="ORCA — Voice-first, Offline Marine Safety Copilot" />

<br/>

<a href="https://orca-app-gold.vercel.app" target="_blank">
  <img src="https://readme-typing-svg.demolab.com?font=Orbitron&weight=800&size=28&pause=1000&color=4F46E5&center=true&vCenter=true&width=820&height=60&lines=IS+IT+SAFE+TO+GO+TO+SEA+TODAY%3F;WHERE+ARE+THE+FISH%3F;SAFETY+GATE+THAT+FAILS+CLOSED;9+COASTAL+LANGUAGES+%C2%B7+100%25+OFFLINE" alt="Typing SVG" />
</a>

<br/>

[![Mobile](https://img.shields.io/badge/Mobile-React%20Native%200.86%20%7C%20Expo%20SDK%2057-4F46E5?style=for-the-badge&logo=expo&logoColor=white)](https://expo.dev/)
[![Backend](https://img.shields.io/badge/Backend-Node.js%20%7C%20Express%205-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![Database](https://img.shields.io/badge/Database-PostgreSQL%20%7C%20PostGIS%20%7C%20PGlite-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgis.net/)
[![Dashboard](https://img.shields.io/badge/Dashboard-React%2019%20%7C%20Vite%20%7C%20Leaflet-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev/)
[![Speech](https://img.shields.io/badge/On--device%20AI-whisper.cpp%20%7C%20IndicTTS-F07A5A?style=for-the-badge&logo=openai&logoColor=white)](https://github.com/ggerganov/whisper.cpp)

<br/>

![SIH](https://img.shields.io/badge/SIH%202026-SIH26176-C4BBF0?style=flat-square&labelColor=1B1C18)
![Tests](https://img.shields.io/badge/tests-166%20passing-A3C12B?style=flat-square&labelColor=1B1C18)
![Offline](https://img.shields.io/badge/mode-offline--first-E3F163?style=flat-square&labelColor=1B1C18)
![Languages](https://img.shields.io/badge/languages-9-F07A5A?style=flat-square&labelColor=1B1C18)
![TypeScript](https://img.shields.io/badge/TypeScript-strict-3178C6?style=flat-square&logo=typescript&logoColor=white&labelColor=1B1C18)

<br/>

> **🌊 "Jaan pehle, kamai baad me." A voice-first, offline copilot that tells a fisherman whether it is safe to go to sea, and where the fish are, in his own language. When a warning is active, the fishing advice cannot run at all.**

[🌐 **LIVE WEBSITE**](https://orca-app-gold.vercel.app) &nbsp;•&nbsp; [📲 **DOWNLOAD APK**](https://orca-app-gold.vercel.app/ORCA-1.0.1.apk) &nbsp;•&nbsp; [🏗️ **ARCHITECTURE**](#-system-architecture) &nbsp;•&nbsp; [🚀 **QUICKSTART**](#-quickstart)

<br/>

<img src=".github/assets/banner.svg" alt="ORCA preview" width="100%" />

</div>

---

<br/>

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=4F46E5&height=60&text=🏆%20WHAT%20MAKES%20ORCA%20DIFFERENT&fontColor=ffffff&fontSize=30" alt="What makes ORCA different"/>
</div>

<br/>

Most marine apps are dashboards of numbers: wave charts, wind barbs and bulletins in English that assume a data connection and a literate reader. **ORCA** turns them into one clear, spoken answer in the fisherman's language, and it keeps working far from the coast.

- **🛡️ Safety Gate that fails closed:** five deterministic checks with no AI in the decision. Missing, unreadable or stale data (older than 12 hours) **blocks** fishing advice instead of guessing.
- **🔒 Locked in code, not hidden in the UI:** a safe result mints a **SafePass**. The trip planner refuses to run without one, so during a warning the fishing path is unreachable, and a test suite proves it.
- **🎙️ Voice-first and fully offline:** on-device speech-to-text with **whisper.cpp** (`whisper.rn`), keyword intent detection across **9 languages** with code-mixed speech, and spoken replies from recorded clips or the phone's own voice.
- **📝 No machine translation for safety text:** every warning uses fixed, pre-written templates in தமிழ் · తెలుగు · മലയാളം · বাংলা · ଓଡ଼ିଆ · मराठी · ಕನ್ನಡ · हिन्दी · English.
- **🆘 SOS that is never lost:** a 10-second cancel window, then an SOS with the **last 6 hours of GPS trail**, queued offline and sent automatically when signal returns.
- **🚩 IMBL border alarm:** a full-screen siren, vibration and a spoken *"turn back"* at 5 km from the India–Sri Lanka maritime line.
- **🗺️ ORCA Command:** officers see the live fleet, dispatch SOS alerts and broadcast district warnings that land in **every phone's Safety Gate** and go out by SMS in each fisherman's language.

<br/>

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=1B1C18&height=60&text=🛡️%20THE%20SAFETY%20GATE&fontColor=E3F163&fontSize=30" alt="The Safety Gate"/>
</div>

<br/>

<img src=".github/assets/safety-gate.svg" alt="Safety Gate animation — calm conditions pass, a cyclone warning blocks" width="100%" />

<br/>

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#E9E5FB','primaryTextColor':'#1B1C18','primaryBorderColor':'#4F46E5','lineColor':'#686B63'}}}%%
graph TD
    A[🎙️ Fisherman asks: Can I go today?] --> B[📦 Cached marine bundle on the phone]
    B --> C{Data present and ≤ 12 h old?}
    C -->|No| X[🔴 BLOCKED · NO_DATA / STALE_DATA]
    C -->|Yes| D{Cyclone or active warning?}
    D -->|Yes| X2[🔴 BLOCKED · CYCLONE_WARNING]
    D -->|No| E{Do-not-venture advisory?}
    E -->|Yes| X3[🔴 BLOCKED · DO_NOT_VENTURE]
    E -->|No| F{Waves ≤ 2.5 m and wind ≤ 40 km/h?}
    F -->|No| X4[🔴 BLOCKED · HIGH_WAVES / STRONG_WIND]
    F -->|Yes| G[🟢 SAFE · SafePass minted, valid 30 min]
    G --> H[🧭 Trip planner: 18 km SE · ~24 L diesel · back by 4 PM]
    X & X2 & X3 & X4 --> Z[🔒 Fixed warning in the fisherman's language · trip planner never runs]

    classDef stop fill:#FBE4E1,stroke:#E0685A,color:#1B1C18
    classDef go fill:#EEF5C4,stroke:#A3C12B,color:#1B1C18
    class X,X2,X3,X4,Z stop
    class G,H go
```

| # | Check | Blocks when | Reason code |
| :-: | :--- | :--- | :--- |
| 1 | **Warnings** | any IMD / INCOIS / officer warning is active | `CYCLONE_WARNING` · `ACTIVE_WARNING` |
| 2 | **Waves** | above **2.5 m**, or unknown | `HIGH_WAVES` · `NO_DATA` |
| 3 | **Wind** | above **40 km/h**, or unknown | `STRONG_WIND` · `NO_DATA` |
| 4 | **Advisory** | a "do not venture" advisory is issued | `DO_NOT_VENTURE` |
| 5 | **Freshness** | data is older than **12 hours** | `STALE_DATA` |

> 🔒 *Calling the trip planner without a genuine, unexpired SafePass throws `SafetyGateError: Fishing advice requires a SafePass issued by the Safety Gate.` A pass can only be created inside `evaluateSafety()`, where it is tracked in a private `WeakSet`, so a forged object is always rejected.*

<br/>

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=4F46E5&height=60&text=🏗️%20SYSTEM%20ARCHITECTURE&fontColor=ffffff&fontSize=30" alt="System architecture"/>
</div>

<br/>

One shared brain, **`@orca/core`**, runs **identically on the phone and on the server**. The phone never needs a connection to make a safety decision.

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#FFFFFF','primaryTextColor':'#1B1C18','primaryBorderColor':'#A9AC9F','lineColor':'#686B63','clusterBkg':'#F4F5EE','clusterBorder':'#C4BBF0'}}}%%
flowchart TB
    subgraph Client [📱 Mobile App · Expo SDK 57 + React Native 0.86]
        FP[Fisherman Voice UI]
        STT[whisper.rn · offline speech-to-text]
        CORE1[["@orca/core · Safety Gate · Intent · Trip Planner"]]
        LITE[(SQLite · offline bundle + SOS queue)]
        BG[Background GPS · 5-min trail · IMBL alarm]
    end

    subgraph Command [🗺️ ORCA Command · React 19 + Vite + Leaflet]
        OP[Officer Fleet Map · SOS Dispatch · Broadcast]
    end

    subgraph Server [🖥️ API Server · Node.js + Express 5]
        API[REST API · zod · helmet · rate limiting · JWT]
        ING[Hourly Ingestion · node-cron]
        CORE2[["@orca/core · same pipeline for IVR / SMS"]]
        ASR[whisper.cpp ASR]
    end

    subgraph Data [🗄️ Data & Spatial Layer]
        PG[(PostgreSQL + PostGIS · or embedded PGlite)]
    end

    subgraph External [🌐 External Sources]
        OM[Open-Meteo · live sea state]
        IMD[IMD · cyclone & marine warnings]
        INC[INCOIS · PFZ fishing zones]
        TW[Twilio · Verify OTP + SMS]
    end

    FP --> STT --> CORE1
    BG --> CORE1
    CORE1 <--> LITE
    LITE <-->|/bundle · /positions · /sos| API
    OP <-->|/fleet · /broadcast · /warnings| API
    API --- CORE2
    API --- ASR
    API <--> PG
    ING --> PG
    OM & IMD & INC --> ING
    API <--> TW

    classDef core fill:#1B1C18,stroke:#1B1C18,color:#E3F163
    class CORE1,CORE2 core
```

<br/>

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=C4BBF0&height=60&text=🔄%20HOW%20A%20QUESTION%20IS%20ANSWERED&fontColor=1B1C18&fontSize=30" alt="How a question is answered"/>
</div>

<br/>

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','actorBkg':'#E9E5FB','actorBorder':'#4F46E5','actorTextColor':'#1B1C18','signalColor':'#3A3C35','signalTextColor':'#1B1C18','noteBkgColor':'#EEF5C4','noteBorderColor':'#A3C12B'}}}%%
sequenceDiagram
    autonumber
    actor F as 🧑‍✈️ Fisherman
    participant App as 📱 ORCA App
    participant STT as 🎙️ whisper.rn
    participant I as 🔤 Intent Parser
    participant G as 🛡️ Safety Gate
    participant P as 🧭 Trip Planner

    F->>App: Hold mic · "இன்று போகலாமா?"
    App->>STT: audio (on-device, offline)
    STT-->>App: transcript
    App->>I: transcript + language
    I-->>App: SAFETY_CHECK (safety words always win)
    App->>G: cached marine conditions
    alt Sea is safe
        G-->>App: ✅ SafePass (30 min)
        App->>P: plan(zone, SafePass)
        P-->>App: 18 km SE · ~24 L · back by 4 PM
        App-->>F: 🟢 green card + spoken Tamil reply + return reminder
    else Warning or stale data
        G-->>App: ⛔ blocked + reasons + warning end time
        App-->>F: 🔴 red card + fixed Tamil warning
        Note over P: Never called without a SafePass
    end
```

<br/>

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=F07A5A&height=60&text=🆘%20SOS%20%26%20BORDER%20SAFETY&fontColor=ffffff&fontSize=30" alt="SOS and border safety"/>
</div>

<br/>

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#FBE4E1','primaryTextColor':'#1B1C18','primaryBorderColor':'#E0685A','lineColor':'#686B63'}}}%%
stateDiagram-v2
    direction LR
    [*] --> Countdown: 🆘 SOS pressed
    Countdown --> [*]: cancelled within 10 s
    Countdown --> Queued: saved with last 6 h trail
    Queued --> Sent: signal available
    Sent --> Queued: no signal · retry
    Sent --> Relayed: control room + family SMS
    Relayed --> Dispatched: officer responds
    Dispatched --> [*]
```

| Border level | Distance to IMBL | What the fisherman gets |
| :--- | :--- | :--- |
| 🟢 `CLEAR` | more than 10 km | normal operation |
| 🟠 `WATCH` | 10 km or less | warning chip on the home screen |
| 🔴 `ALARM` | 5 km or less | full-screen alarm · siren · vibration · spoken *"turn back"* |
| ⛔ `CROSSED` | across the line | crossed-border message until the boat returns |

> ⚠️ *The IMBL coordinates in `packages/core/src/imbl.ts` come from the published 1974/1976 agreements. Replace them with the official Survey of India / Coast Guard dataset before real-world use.*

<br/>

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=1B1C18&height=60&text=📡%20LIVE%20DATA%20PIPELINE&fontColor=ffffff&fontSize=30" alt="Live data pipeline"/>
</div>

<br/>

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#E9E5FB','primaryTextColor':'#1B1C18','primaryBorderColor':'#4F46E5','lineColor':'#686B63'}}}%%
graph LR
    A[⏱️ node-cron · every hour] --> B[🌊 Open-Meteo · 9 harbours]
    A --> C[📰 IMD + INCOIS normalised feeds]
    B & C --> D{✅ Valid?}
    D -->|Yes| E[(🗄️ PostGIS)]
    D -->|No / source down| F[♻️ Keep last good data]
    F --> E
    E --> G[📦 /bundle · sea state · warnings · PFZ zones · prices]
    G --> H[📱 Cached on the phone]
    H --> I{Older than 12 h?}
    I -->|No| J[🟢 Gate may pass]
    I -->|Yes| K[🔴 Gate blocks · STALE_DATA]
```

Sea state comes live from **Open-Meteo** every hour for 9 harbours, one per coastal language. IMD and INCOIS do not publish stable JSON APIs, so the server accepts one normalised feed per source (shapes in `apps/server/src/ingest/feeds.ts`). If a source fails, the last good data is kept, and its age stays visible on every phone.

<br/>

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=4F46E5&height=60&text=🔐%20ROLES%20%26%20ACCESS&fontColor=ffffff&fontSize=30" alt="Roles and access"/>
</div>

<br/>

| Role | Where | Access & rules |
| :--- | :--- | :--- |
| **Fisherman** | 📱 Mobile app | OTP login, language + harbour + family contact, Safety Gate answers, trip plans, SOS, trail upload |
| **Fisheries Officer** | 🗺️ ORCA Command | Allow-listed officer role, live fleet map, SOS dispatch, per-boat SMS, 9-language district broadcast, officer warnings |
| **Anyone (no login)** | 🌐 API | Health, harbour bundles, OTP, **SOS (never rejected, idempotent)**, speech-to-text, `/ask` for IVR / SMS channels |

> 🔒 *An officer warning is not just a notification. It is stored as a warning, so it enters **every phone's Safety Gate** on the next bundle and blocks fishing advice across the district.*

<br/>

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=C4BBF0&height=60&text=🧰%20TECH%20STACK&fontColor=1B1C18&fontSize=30" alt="Tech stack"/>
</div>

<br/>

| Layer | Package | Technologies |
| :--- | :--- | :--- |
| 🧠 **Shared brain** | `@orca/core` | TypeScript · Turf.js (distance, bearing, point-to-line) · suncalc · fixed i18n templates |
| 📱 **Mobile** | `@orca/mobile` | Expo SDK 57 · React Native 0.86 · React 19 · expo-router · whisper.rn · expo-speech · expo-sqlite · expo-location · expo-task-manager · expo-notifications · expo-sms |
| 🖥️ **Server** | `@orca/server` | Node.js · Express 5 · PGlite + PostGIS / PostgreSQL · node-cron · zod · helmet · express-rate-limit · JWT · multer · pino |
| 🗺️ **Dashboard** | `@orca/dashboard` | React 19 · Vite 8 · Leaflet · react-leaflet · react-router |
| 🔊 **Voice tooling** | `tools/voice` | Python · AI4Bharat IndicTTS · native-speaker recordings |
| 🧪 **Quality** | all | Vitest · Supertest · embedded PostGIS integration tests · EAS Build |

<br/>

---


---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=F07A5A&height=60&text=🚀%20QUICKSTART&fontColor=ffffff&fontSize=30" alt="Quickstart"/>
</div>

<br/>

### 1️⃣ Clone & install

```bash
git clone <your-repo-url> orca
cd orca
npm install            # installs every workspace (npm workspaces)
```

### 2️⃣ Run the platform

```bash
npm run server         # API on :4000 · embedded PostGIS · live Open-Meteo sea state
npm run dashboard      # ORCA Command on :5173 (set VITE_API_URL if the API is not on :4000)
npm run mobile         # Expo · scan the QR code with Expo Go (SDK 57)
```

### 3️⃣ Prove the Safety Gate

```bash
npm test               # 166 tests · 127 core + 39 server
npm run test:gate      # just the Safety Gate proof (show this to the jury)
npm run test:db        # server store against a real embedded PostGIS (~40 s)
```

> 💡 *Dev login everywhere: any number, OTP `123456`. In ORCA Command, **Load demo fleet** puts 40 simulated boats on the map. Without a server, the app runs in **offline demo mode** on bundled Nagapattinam scenarios. To connect a phone to your PC, set `EXPO_PUBLIC_API_URL=http://<your-PC-IP>:4000` in `apps/mobile/.env`.*

> 📦 *Android APK: built in the cloud with EAS (no local Android SDK needed). See [`docs/BUILD.md`](docs/BUILD.md), or grab the latest build from the [website](https://orca-app-gold.vercel.app).*

<br/>

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=4F46E5&height=60&text=🎬%2090-SECOND%20DEMO&fontColor=ffffff&fontSize=30" alt="90-second demo"/>
</div>

<br/>

| # | Do this | You'll see |
| :-: | :--- | :--- |
| 1 | Log in: pick **தமிழ்**, choose *Fisherman*, OTP `123456` | Home screen with the big mic |
| 2 | Tap **"இன்று போகலாமா?"** | 🟢 Green card + spoken Tamil: 18 km SE, ~24 L diesel, back by 4:00 PM |
| 3 | ⚙ Settings → Demo scenario → **Cyclone day**, then ask again | 🔴 Red card, warning until *வியாழன் மாலை 6:00* · Zone Map locked |
| 4 | Run `npm run test:gate` | ✅ Every test passes |
| 5 | Turn on airplane mode, ask again | Still answers · data age still visible |
| 6 | Press **SOS** | 10 s cancel window → queued with 6 h trail → SMS opens → auto-flush on signal |
| 7 | ⚙ Settings → Demo boat position → **Near border** | Full-screen alarm, siren and spoken "turn back" |
| 8 | After a green answer | "Return reminder set for 4:00 PM" · 2 notifications scheduled |

<br/>

<details>
<summary><b>🔌 API reference (click to expand)</b></summary>

<br/>

| Endpoint | Access | What it does |
| :--- | :--- | :--- |
| `GET /health` | anyone | store, OTP/SMS/ASR mode, last ingestion |
| `GET /harbours` · `GET /bundle?harbour=` | anyone | offline bundle: sea state + warnings + PFZ zones + prices |
| `POST /auth/otp` · `POST /auth/verify` | anyone | OTP login (Twilio Verify, dev code `123456`); officer role is allow-listed |
| `GET` · `PATCH /me` | logged in | language, harbour, family contact |
| `POST /sos` | **anyone** | never rejected, idempotent; texts the control room and family in the fisherman's language |
| `POST /positions` | fisherman | breadcrumb upload → fleet map |
| `POST /asr` | anyone | audio → text via whisper.cpp (503 → phone falls back to buttons) |
| `POST /ask` | anyone | same core pipeline server-side, for IVR / SMS channels |
| `GET /fleet` · `GET` · `PATCH /sos` | officer | boats at sea, border status, return ETA, SOS dispatch |
| `POST /broadcast` · `POST /notify` | officer | district warning in every language; text one boat |
| `GET` · `POST` · `DELETE /warnings` | officer | officer warnings that enter every phone's Safety Gate |
| `POST /demo/scenario` · `POST /ingest/run` | officer | stage a demo scenario; run ingestion now |

</details>

<details>
<summary><b>📁 Repository layout (click to expand)</b></summary>

<br/>

```
orca/
├── packages/core        @orca/core: shared brain (phone AND server)
│   ├── src/safetyGate.ts    5 checks · fails closed · unforgeable SafePass
│   ├── src/intent.ts        keyword intent · 9 languages + code-mixing · no LLM
│   ├── src/tripPlanner.ts   Turf.js distance · direction · diesel · return-by
│   ├── src/copilot.ts       question → gate → fixed-template answer
│   ├── src/imbl.ts          India–Sri Lanka border distance + side-of-line
│   ├── src/trail.ts         breadcrumb trail · 1 point / 5 min · last 6 h
│   ├── src/i18n/            fixed templates: ta te ml bn or mr kn hi en
│   └── test/                127 tests
├── apps/mobile          Expo SDK 57 / React Native app (fisherman + officer)
├── apps/server          Express + PostGIS: ingestion, OTP, SOS relay, fleet, ASR
├── apps/dashboard       ORCA Command: React + Vite + Leaflet
├── tools/voice          render fixed safety sentences to clips (IndicTTS)
└── docs/BUILD.md        Android APK build with EAS
```

</details>

<details>
<summary><b>🧭 Safety principles (click to expand)</b></summary>

<br/>

- **No AI in the safety decision:** plain `if/else`, deterministic and testable.
- **Fails closed:** missing, unreadable or stale (more than 12 h old) data blocks the fishing answer.
- **No machine translation for safety text:** fixed templates, with native-speaker review tracked in `packages/core/TRANSLATIONS.md`.
- **Over-triggering is acceptable, a miss is not:** safety keywords override fishing keywords.
- **The data's age is always visible.**

</details>

<br/>

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:C4BBF0,45:4F46E5,100:1B1C18&height=150&section=footer&text=Jaan%20pehle%2C%20kamai%20baad%20me.&fontSize=30&fontColor=ffffff&fontAlignY=62" width="100%" alt="Footer" />

*ORCA: built for the fishermen of India's coast · Smart India Hackathon 2026 · SIH26176* 🇮🇳

</div>
