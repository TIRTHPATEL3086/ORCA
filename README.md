<div align="center">

<img src=".github/assets/banner.svg" alt="ORCA — Marine intelligence that travels with you" width="100%" />

<br/>

<a href="https://orca-app-gold.vercel.app">
  <img src="https://readme-typing-svg.demolab.com?font=Inter&weight=700&size=22&duration=2600&pause=900&color=4F46E5&center=true&vCenter=true&width=760&lines=Is+it+safe+to+go+to+sea+today%3F;Where+are+the+fish%3F;Voice-first.+Offline-first.+9+coastal+languages.;Jaan+pehle%2C+kamai+baad+me." alt="Is it safe to go to sea today? Where are the fish?" />
</a>

<br/><br/>

<a href="https://orca-app-gold.vercel.app/ORCA-1.0.1.apk"><img src="https://img.shields.io/badge/Download-Android_APK_v1.0.1-1B1C18?style=for-the-badge&logo=android&logoColor=E3F163&labelColor=1B1C18" alt="Download the Android APK"/></a>
<a href="https://orca-app-gold.vercel.app"><img src="https://img.shields.io/badge/Live-Landing_page-4F46E5?style=for-the-badge&logo=vercel&logoColor=white" alt="Live landing page"/></a>
<br/>
<img src="https://img.shields.io/badge/SIH_2026-SIH26176-C4BBF0?style=flat-square&labelColor=1B1C18" alt="SIH 2026 · SIH26176"/>
<img src="https://img.shields.io/badge/tests-166_passing-A3C12B?style=flat-square&labelColor=1B1C18" alt="166 tests passing"/>
<img src="https://img.shields.io/badge/offline-first-E3F163?style=flat-square&labelColor=1B1C18" alt="Offline first"/>
<img src="https://img.shields.io/badge/languages-9-F07A5A?style=flat-square&labelColor=1B1C18" alt="9 languages"/>
<img src="https://img.shields.io/badge/safety_decision-no_AI-FBE4E1?style=flat-square&labelColor=1B1C18" alt="No AI in the safety decision"/>
<img src="https://img.shields.io/badge/TypeScript-100%25-3178C6?style=flat-square&logo=typescript&logoColor=white&labelColor=1B1C18" alt="TypeScript"/>

<br/><br/>

**[Why ORCA](#-why-orca)** · **[Safety Gate](#-the-safety-gate)** · **[Features](#-features)** · **[Architecture](#-architecture)** · **[Flows](#-how-it-flows)** · **[Tech stack](#-tech-stack)** · **[Quick start](#-quick-start)** · **[Demo](#-the-90-second-demo)** · **[API](#-server-api)**

<br/>

<img src=".github/assets/marquee.svg" alt="Jaan pehle, kamai baad me · Offline-first · Safety Gate fails closed · 9 coastal languages · One-tap SOS · Border alarm" width="100%" />

</div>

<br/>

## 🌊 Why ORCA

> **Because the sea deserves more than guesswork!**

ORCA is a **voice-first, offline** app for fishermen. It answers two questions in the fisherman's own language:

<table>
<tr>
<td width="50%" valign="top">

### 01 · "Is it safe to go to sea today?"

Checks cyclone and sea warnings from **IMD** and **INCOIS**, plus live wave and wind data for the harbour. If anything is wrong, the answer is a red card with the warning and the time it ends.

</td>
<td width="50%" valign="top">

### 02 · "Where are the fish?"

On a safe day, ORCA points to potential fishing zones with the **distance, direction, diesel needed and a return-by time**, so every trip is planned before the boat leaves.

</td>
</tr>
</table>

The **Safety Gate** is the core design decision. When a warning is active, the code path that gives fishing advice **cannot run**. The screen doesn't just hide it, and a test suite proves it.

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🛡️ The Safety Gate

<img src=".github/assets/safety-gate.svg" alt="Safety Gate animation: five checks, calm day passes, cyclone day blocks" width="100%" />

The gate is plain `if/else` logic in [`packages/core/src/safetyGate.ts`](packages/core/src/safetyGate.ts). The same input always gives the same answer, it fails closed, and a SAFE result mints a **SafePass** that the trip planner demands before it will run.

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#E9E5FB','primaryTextColor':'#1B1C18','primaryBorderColor':'#4F46E5','lineColor':'#686B63','secondaryColor':'#EEF5C4','tertiaryColor':'#FBE4E1'}}}%%
flowchart TD
    Q([🎙️ Fisherman asks a question]):::ink --> D{Marine data<br/>available?}
    D -- "no / unreadable" --> NODATA[NO_DATA]:::pink
    D -- yes --> C5{5 · Data age<br/>≤ 12 h?}
    C5 -- no --> STALE[STALE_DATA]:::pink
    C5 -- yes --> C1
    STALE --> C1{1 · Active warning?}
    C1 -- cyclone --> CY[CYCLONE_WARNING]:::pink
    C1 -- other --> AW[ACTIVE_WARNING]:::pink
    C1 -- none --> C4
    CY --> C4
    AW --> C4{4 · Do-not-venture<br/>advisory?}
    C4 -- yes --> DNV[DO_NOT_VENTURE]:::pink
    C4 -- no --> C2
    DNV --> C2{2 · Waves<br/>≤ 2.5 m?}
    C2 -- no --> HW[HIGH_WAVES]:::pink
    C2 -- yes --> C3
    HW --> C3{3 · Wind<br/>≤ 40 km/h?}
    C3 -- no --> SW[STRONG_WIND]:::pink
    C3 -- yes --> R
    SW --> R{Any reason<br/>collected?}
    NODATA --> BLOCK
    R -- yes --> BLOCK[🔴 BLOCKED<br/>fixed, pre-written warning<br/>in the fisherman's language]:::stop
    R -- no --> SAFE[🟢 SAFE<br/>SafePass minted · valid 30 min]:::go
    SAFE --> TP[🧭 Trip planner<br/>assertSafePass ✔]:::lime
    BLOCK -. "no SafePass" .-> X[🔒 Trip planner throws<br/>SafetyGateError]:::ink

    classDef ink fill:#1B1C18,color:#ffffff,stroke:#1B1C18
    classDef pink fill:#FBE4E1,stroke:#E0685A,color:#1B1C18
    classDef lime fill:#EEF5C4,stroke:#A3C12B,color:#1B1C18
    classDef go fill:#E3F163,stroke:#A3C12B,color:#1B1C18,font-weight:bold
    classDef stop fill:#F6B8AE,stroke:#9F1D1D,color:#1B1C18,font-weight:bold
```

<details>
<summary><b>🔍 The SafePass, in code</b></summary>

```ts
// packages/core/src/safetyGate.ts
export const DEFAULT_THRESHOLDS = Object.freeze({
  maxWaveHeightM: 2.5,    // small-craft limit
  maxWindSpeedKmph: 40,   // IMD advises staying ashore at 40–50 km/h
  maxDataAgeHours: 12,    // older data cannot be trusted
});

// Every fishing-related function must call this first.
export function assertSafePass(pass: unknown, now = new Date()): asserts pass is SafePass {
  if (typeof pass !== 'object' || pass === null || !minted.has(pass as SafePass)) {
    throw new SafetyGateError('Fishing advice requires a SafePass issued by the Safety Gate.');
  }
  if (now.getTime() > Date.parse((pass as SafePass).expiresAt)) {
    throw new SafetyGateError('SafePass expired — re-run the Safety Gate.');
  }
}
```

A SafePass can only be created inside `evaluateSafety()` (it is tracked in a private `WeakSet`), so a forged object never unlocks the trip planner.

</details>

### 📊 The demo scenarios against the gate limits

The bundled Nagapattinam demo ships three sea states. Bars are the conditions and the line is the gate limit. Anything above the line is blocked.

<table>
<tr>
<td width="50%">

```mermaid
%%{init: {'theme':'base','themeVariables':{'xyChart':{'plotColorPalette':'#C4BBF0, #E0685A','backgroundColor':'#F4F5EE','titleColor':'#1B1C18','xAxisLabelColor':'#3A3C35','yAxisLabelColor':'#3A3C35'}}}}%%
xychart-beta
    title "Wave height (m) · limit 2.5 m"
    x-axis ["Calm", "Rough", "Cyclone"]
    y-axis "metres" 0 --> 4
    bar [1.1, 2.9, 3.8]
    line [2.5, 2.5, 2.5]
```

</td>
<td width="50%">

```mermaid
%%{init: {'theme':'base','themeVariables':{'xyChart':{'plotColorPalette':'#E3F163, #E0685A','backgroundColor':'#F4F5EE','titleColor':'#1B1C18','xAxisLabelColor':'#3A3C35','yAxisLabelColor':'#3A3C35'}}}}%%
xychart-beta
    title "Wind speed (km/h) · limit 40 km/h"
    x-axis ["Calm", "Rough", "Cyclone"]
    y-axis "km/h" 0 --> 70
    bar [18, 46, 65]
    line [40, 40, 40]
```

</td>
</tr>
</table>

| Scenario | Waves | Wind | Warning | Gate result |
|---|---|---|---|---|
| 🟢 **Calm day** | 1.1 m | 18 km/h | none | **SAFE**: trip plan + return reminder |
| 🟠 **Rough day** | 2.9 m | 46 km/h | none | **BLOCKED**: `HIGH_WAVES`, `STRONG_WIND` |
| 🔴 **Cyclone day** | 3.8 m | 65 km/h | IMD cyclone, do-not-venture | **BLOCKED**: `CYCLONE_WARNING`, `DO_NOT_VENTURE`, `HIGH_WAVES`, `STRONG_WIND` |

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## ✨ Features

<table>
<tr>
<td width="33%" valign="top">

#### 🎙️ Voice-first
Hold the big button and ask. **On-device whisper.cpp** (`whisper.rn`) turns speech into text offline. ORCA replies aloud with recorded clips or the phone's own text-to-speech.

</td>
<td width="33%" valign="top">

#### 📴 Offline-first
Bundled data and on-device logic. It works in airplane mode, and **the age of the data is always on screen**.

</td>
<td width="33%" valign="top">

#### 🆘 One-tap SOS
A 10-second cancel window, then the SOS is queued with the **last 6 hours of trail**. SMS opens, and the queue flushes itself when signal returns.

</td>
</tr>
<tr>
<td valign="top">

#### 🚩 Border alarm
A full-screen siren, vibration and a spoken **"turn back"** near the India–Sri Lanka IMBL. It repeats until "I'm turning back" is tapped.

</td>
<td valign="top">

#### 🧭 Trip planner
Built on Turf.js: **distance, direction, diesel, and a return-by time** before dark (sunset from `suncalc`).

</td>
<td valign="top">

#### ⏰ Return reminders
Two local notifications, one 30 minutes before and one at the return time. It is spoken aloud if the app is open.

</td>
</tr>
<tr>
<td valign="top">

#### 🗣️ 9 languages
தமிழ் · తెలుగు · മലയാളം · বাংলা · ଓଡ଼ିଆ · मराठी · ಕನ್ನಡ · हिन्दी · English, with **code-mixed speech** understood.

</td>
<td valign="top">

#### 🖥️ ORCA Command
An officer dashboard with a live fleet map, IMBL and zones, SOS dispatch, per-boat SMS, and **broadcasts in 9 languages**.

</td>
<td valign="top">

#### 🔐 OTP login
Twilio Verify OTP login, with a dev code of `123456` for demos. The officer role is allow-listed.

</td>
</tr>
</table>

<div align="center">
<img src=".github/assets/stats.svg" alt="9 languages · 9 live harbours · 166 automated tests · 5 gate checks · 12 h max data age · 6 h SOS trail" width="100%" />
</div>

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🏗️ Architecture

One shared brain, **`@orca/core`**, runs **identically on the phone (offline) and on the server**. The phone never needs the server to make a safety decision.

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#E9E5FB','primaryTextColor':'#1B1C18','primaryBorderColor':'#4F46E5','lineColor':'#686B63','clusterBkg':'#F4F5EE','clusterBorder':'#DCDFCB'}}}%%
flowchart LR
    subgraph EXT["🌐 Data sources"]
        OM["Open-Meteo<br/>live sea state"]:::lav
        IMD["IMD feed<br/>cyclone / warnings"]:::lav
        INC["INCOIS feed<br/>PFZ zones · swell"]:::lav
        TW["Twilio<br/>Verify · SMS"]:::lav
    end

    subgraph PHONE["📱 @orca/mobile · Expo SDK 57"]
        UI["Voice UI<br/>big buttons"]:::lime
        STT["whisper.rn<br/>offline STT"]:::lime
        CORE1["@orca/core<br/>Safety Gate · intent · trip planner"]:::ink
        CACHE[("SQLite<br/>offline bundle · SOS queue")]:::lime
        OUT["Speech · haptics<br/>notifications"]:::lime
        BG["Background location<br/>trail · IMBL alarm"]:::lime
    end

    subgraph SERVER["🖥️ @orca/server · Node + Express 5"]
        API["REST API<br/>zod · helmet · rate limit"]:::pink
        ING["Hourly ingestion<br/>node-cron"]:::pink
        CORE2["@orca/core<br/>same pipeline"]:::ink
        DB[("PostGIS<br/>PGlite embedded or Postgres")]:::pink
        ASR["whisper.cpp ASR"]:::pink
    end

    subgraph DASH["🗺️ @orca/dashboard · ORCA Command"]
        MAP["React + Vite<br/>Leaflet fleet map"]:::lav
    end

    OM --> ING
    IMD --> ING
    INC --> ING
    ING --> DB
    API <--> DB
    API --- CORE2
    API <--> TW
    API --- ASR
    UI --> STT --> CORE1 --> OUT
    CORE1 <--> CACHE
    BG --> CORE1
    CACHE <-- "/bundle · /positions · /sos" --> API
    MAP <-- "/fleet · /broadcast · /warnings" --> API

    classDef ink fill:#1B1C18,color:#E3F163,stroke:#1B1C18,font-weight:bold
    classDef lime fill:#EEF5C4,stroke:#A3C12B,color:#1B1C18
    classDef lav fill:#E9E5FB,stroke:#4F46E5,color:#1B1C18
    classDef pink fill:#FBE4E1,stroke:#E0685A,color:#1B1C18
```

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🔄 How it flows

### 1 · Asking a question (fully on the phone)

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','actorBkg':'#E9E5FB','actorBorder':'#4F46E5','actorTextColor':'#1B1C18','signalColor':'#3A3C35','signalTextColor':'#1B1C18','noteBkgColor':'#EEF5C4','noteBorderColor':'#A3C12B','activationBkgColor':'#FBE4E1','activationBorderColor':'#E0685A','sequenceNumberColor':'#ffffff'}}}%%
sequenceDiagram
    autonumber
    actor F as 🧑‍✈️ Fisherman
    participant App as 📱 ORCA app
    participant STT as whisper.rn
    participant I as Intent parser
    participant G as 🛡️ Safety Gate
    participant P as 🧭 Trip planner
    participant V as 🔊 Voice

    F->>App: Hold mic · "இன்று போகலாமா?"
    App->>STT: audio (on-device)
    STT-->>App: text
    App->>I: text + language
    I-->>App: SAFETY_CHECK (safety keywords win)
    App->>G: cached marine bundle
    alt Gate SAFE
        G-->>App: SafePass (30 min)
        App->>P: plan(zone, SafePass)
        P-->>App: 18 km SE · ~24 L · back by 4 PM
        App->>V: green card + spoken reply
        Note over App: Return reminder scheduled
    else Gate BLOCKED
        G-->>App: reasons + active-until time
        App->>V: red card + fixed warning template
        Note over P: never called, no SafePass
    end
    V-->>F: answer in Tamil
```

### 2 · Understanding the question

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#E9E5FB','primaryTextColor':'#1B1C18','primaryBorderColor':'#4F46E5','lineColor':'#686B63'}}}%%
flowchart LR
    A["🎙️ Speech<br/>or 🔘 button"]:::lav --> B["Normalise text<br/>9 scripts + code-mixing"]:::lav
    B --> C{"Keyword<br/>intent match<br/>(no LLM)"}
    C -->|"SOS words"| S["🆘 SOS screen"]:::stop
    C -->|"safety words"| G["🛡️ SAFETY_CHECK"]:::lime
    C -->|"fish / zone"| Z["🐟 FISHING_ZONE"]:::lime
    C -->|"return"| R["⏰ RETURN_TIME"]:::lime
    C -->|"weather / price"| W["☁️ WEATHER · 💰 MARKET_PRICE"]:::lime
    Z --> GATE["Every fishing intent<br/>still passes the gate first"]:::ink
    classDef lime fill:#EEF5C4,stroke:#A3C12B,color:#1B1C18
    classDef lav fill:#E9E5FB,stroke:#4F46E5,color:#1B1C18
    classDef stop fill:#FBE4E1,stroke:#E0685A,color:#1B1C18
    classDef ink fill:#1B1C18,color:#E3F163,stroke:#1B1C18
```

> Over-triggering is acceptable, a miss is not. **Safety keywords always override fishing keywords.**

### 3 · Live data ingestion

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#EEF5C4','primaryTextColor':'#1B1C18','primaryBorderColor':'#A3C12B','lineColor':'#686B63'}}}%%
flowchart TD
    CRON(["⏱️ node-cron · every hour"]):::ink --> OM["Open-Meteo marine<br/>9 harbours, 1 per coastal language"]
    CRON --> FEEDS["IMD + INCOIS<br/>1 normalised feed per source"]
    OM --> V{"Valid? (zod)"}
    FEEDS --> V
    V -- yes --> ST[("Store · PostGIS")]:::lav
    V -- "no / source down" --> KEEP["Keep last good data"]:::pink
    KEEP --> ST
    ST --> BUN["/bundle?harbour=<br/>sea state · warnings · PFZ zones · prices"]
    BUN --> PH["📱 Phone caches bundle<br/>(SQLite)"]:::lav
    PH --> AGE{"Data age"}
    AGE -- "≤ 12 h" --> OK["Gate may pass"]:::go
    AGE -- "> 12 h" --> BL["Gate blocks · STALE_DATA"]:::stop
    classDef ink fill:#1B1C18,color:#E3F163,stroke:#1B1C18
    classDef lav fill:#E9E5FB,stroke:#4F46E5,color:#1B1C18
    classDef pink fill:#FBE4E1,stroke:#E0685A,color:#1B1C18
    classDef go fill:#E3F163,stroke:#A3C12B,color:#1B1C18
    classDef stop fill:#F6B8AE,stroke:#9F1D1D,color:#1B1C18
```

### 4 · SOS: never rejected, never lost

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#FBE4E1','primaryTextColor':'#1B1C18','primaryBorderColor':'#E0685A','lineColor':'#686B63'}}}%%
stateDiagram-v2
    [*] --> Pressed: tap SOS
    Pressed --> Countdown: 10 s cancel window
    Countdown --> [*]: cancelled
    Countdown --> Queued: save SOS + last 6 h trail
    Queued --> SMS: open SMS to control room
    Queued --> Sending: signal available
    Sending --> Delivered: POST /sos (idempotent)
    Sending --> Queued: no signal, retry on reconnect
    Delivered --> Relayed: server texts control room + family<br/>in the fisherman's language
    Relayed --> Dispatched: officer dispatches on ORCA Command
    Dispatched --> [*]
```

### 5 · Border alarm (IMBL)

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#E9E5FB','primaryTextColor':'#1B1C18','primaryBorderColor':'#4F46E5','lineColor':'#686B63'}}}%%
stateDiagram-v2
    direction LR
    CLEAR: 🟢 CLEAR<br/>more than 10 km
    WATCH: 🟠 WATCH<br/>10 km or less
    ALARM: 🔴 ALARM<br/>5 km or less · siren + "turn back"
    CROSSED: ⛔ CROSSED<br/>other side of the line
    [*] --> CLEAR
    CLEAR --> WATCH: boat moves closer
    WATCH --> ALARM: 5 km or less
    ALARM --> CROSSED: crosses IMBL
    ALARM --> WATCH: "I'm turning back"
    WATCH --> CLEAR: moves away
    CROSSED --> ALARM: returns
```

> ⚠️ The IMBL coordinates in [`packages/core/src/imbl.ts`](packages/core/src/imbl.ts) come from the published 1974/1976 agreements. Replace them with the official Survey of India / Coast Guard dataset before real use.

### 6 · Officer broadcast reaches every Safety Gate

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','actorBkg':'#EEF5C4','actorBorder':'#A3C12B','actorTextColor':'#1B1C18','signalColor':'#3A3C35','noteBkgColor':'#E9E5FB','noteBorderColor':'#4F46E5'}}}%%
sequenceDiagram
    actor O as 👮 Fisheries officer
    participant D as 🗺️ ORCA Command
    participant S as 🖥️ Server
    participant T as ✉️ Twilio SMS
    participant P as 📱 Phones at sea
    O->>D: New district warning
    D->>S: POST /broadcast
    S->>S: store officer warning
    S->>T: SMS to each fisherman<br/>in their own language (9)
    T-->>P: SMS arrives even without data
    P->>S: next GET /bundle
    S-->>P: warning inside the bundle
    Note over P: Safety Gate now BLOCKS<br/>fishing advice on every phone
```

### 7 · A fishing day with ORCA

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif'}}}%%
journey
    title A fisherman's day
    section Before leaving
      Ask "Can I go today?": 5: Fisherman
      Hear the answer in Tamil: 5: Fisherman
      Get zone, diesel and return time: 4: Fisherman
    section At sea
      Trail saved every 5 minutes: 4: ORCA
      Border alarm at 5 km: 3: Fisherman, ORCA
      Return reminder at 3:30 PM: 5: ORCA
    section Emergency
      One-tap SOS with 6 h trail: 3: Fisherman
      Officer dispatches help: 4: Officer
```

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🧰 Tech stack

<div align="center">

<img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white"/>
<img src="https://img.shields.io/badge/React_Native_0.86-20232A?style=for-the-badge&logo=react&logoColor=61DAFB"/>
<img src="https://img.shields.io/badge/Expo_SDK_57-1B1C18?style=for-the-badge&logo=expo&logoColor=white"/>
<img src="https://img.shields.io/badge/React_19-20232A?style=for-the-badge&logo=react&logoColor=61DAFB"/>
<img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white"/>
<img src="https://img.shields.io/badge/Express_5-1B1C18?style=for-the-badge&logo=express&logoColor=white"/>
<img src="https://img.shields.io/badge/PostgreSQL_+_PostGIS-4169E1?style=for-the-badge&logo=postgresql&logoColor=white"/>
<img src="https://img.shields.io/badge/PGlite-embedded-4F46E5?style=for-the-badge&logo=postgresql&logoColor=white"/>
<img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white"/>
<img src="https://img.shields.io/badge/Vite_8-646CFF?style=for-the-badge&logo=vite&logoColor=white"/>
<img src="https://img.shields.io/badge/Leaflet-199900?style=for-the-badge&logo=leaflet&logoColor=white"/>
<img src="https://img.shields.io/badge/Turf.js-geospatial-A3C12B?style=for-the-badge"/>
<img src="https://img.shields.io/badge/whisper.cpp-offline_STT-F07A5A?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Twilio-F22F46?style=for-the-badge&logo=twilio&logoColor=white"/>
<img src="https://img.shields.io/badge/Zod_4-3E67B1?style=for-the-badge&logo=zod&logoColor=white"/>
<img src="https://img.shields.io/badge/Vitest-6E9F18?style=for-the-badge&logo=vitest&logoColor=white"/>
<img src="https://img.shields.io/badge/JWT-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white"/>
<img src="https://img.shields.io/badge/EAS_Build-APK-4630EB?style=for-the-badge&logo=expo&logoColor=white"/>
<img src="https://img.shields.io/badge/Python-IndicTTS-3776AB?style=for-the-badge&logo=python&logoColor=white"/>

</div>

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#E3F163','primaryTextColor':'#1B1C18','primaryBorderColor':'#1B1C18','lineColor':'#686B63','secondaryColor':'#E9E5FB','tertiaryColor':'#FBE4E1'}}}%%
mindmap
  root((ORCA))
    📱 Mobile
      Expo SDK 57
      React Native 0.86
      expo-router
      whisper.rn STT
      expo-speech TTS
      expo-sqlite
      expo-location + task-manager
      expo-notifications
      expo-sms · haptics
    🧠 Core
      Safety Gate
      Keyword intent · 9 languages
      Turf.js trip planner
      suncalc sunset
      IMBL border distance
      Breadcrumb trail
    🖥️ Server
      Express 5
      PGlite + PostGIS
      node-cron ingestion
      Open-Meteo
      Twilio Verify + SMS
      whisper.cpp ASR
      zod · helmet · pino · JWT
    🗺️ Dashboard
      React 19 + Vite 8
      Leaflet map
      react-router
    🧪 Quality
      Vitest · 166 tests
      Supertest API tests
      Real PostGIS test run
```

| Layer | Package | What it uses |
|---|---|---|
| 🧠 **Shared brain** | `@orca/core` | TypeScript, Turf.js (`distance`, `bearing`, `point-to-line-distance`, `nearest-point-on-line`), `suncalc`, fixed i18n templates |
| 📱 **Mobile** | `@orca/mobile` | Expo SDK 57, React Native 0.86, React 19, expo-router, whisper.rn, expo-speech / audio, SQLite, location, task-manager, notifications, SMS, haptics, SVG |
| 🖥️ **Server** | `@orca/server` | Node, Express 5, PGlite + PostGIS (or Postgres via `pg`), node-cron, zod, helmet, express-rate-limit, JWT, multer, pino |
| 🗺️ **Dashboard** | `@orca/dashboard` | React 19, Vite 8, Leaflet + react-leaflet, react-router |
| 🔊 **Voice tools** | `tools/voice` | Python, AI4Bharat IndicTTS, or native-speaker WAV recordings |
| 🧪 **Testing** | all | Vitest, Supertest, embedded PostGIS integration run |

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 📈 By the numbers

<table>
<tr>
<td width="50%">

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','pie1':'#C4BBF0','pie2':'#E3F163','pieStrokeColor':'#1B1C18','pieOuterStrokeColor':'#1B1C18','pieTitleTextColor':'#1B1C18','pieSectionTextColor':'#1B1C18'}}}%%
pie showData
    title Automated tests (166)
    "@orca/core" : 127
    "@orca/server" : 39
```

</td>
<td width="50%">

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','pie1':'#E9E5FB','pie2':'#EEF5C4','pie3':'#FBE4E1','pie4':'#4F46E5','pieStrokeColor':'#1B1C18','pieOuterStrokeColor':'#1B1C18','pieTitleTextColor':'#1B1C18','pieSectionTextColor':'#1B1C18'}}}%%
pie showData
    title API endpoints by access level
    "Anyone" : 8
    "Officer" : 7
    "Logged in" : 1
    "Fisherman" : 1
```

</td>
</tr>
</table>

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 📁 Repository layout

```
📦 orca
├── 📂 packages/core        @orca/core: the shared brain (runs on phone AND server)
│   ├── src/safetyGate.ts   5 checks, fails closed, mints an unforgeable SafePass
│   ├── src/intent.ts       keyword intent, 9 languages + code-mixing, no LLM
│   ├── src/tripPlanner.ts  Turf.js: distance, direction, diesel, return-by time
│   ├── src/copilot.ts      question → gate → fixed-template answer
│   ├── src/i18n/           fixed, pre-written templates: ta te ml bn or mr kn hi en
│   ├── src/imbl.ts         India–Sri Lanka border distance + side-of-line check
│   ├── src/trail.ts        breadcrumb trail (1 point / 5 min, last 6 h)
│   └── test/               127 tests, incl. "fishing fn never called during a warning"
├── 📂 apps/mobile          @orca/mobile: Expo SDK 57 / React Native app (fisherman + officer)
├── 📂 apps/server          @orca/server: Node + Express + PostGIS: ingestion, OTP, SOS relay, fleet, ASR
├── 📂 apps/dashboard       @orca/dashboard: ORCA Command, React + Vite + Leaflet officer dashboard
├── 📂 tools/voice          render fixed safety sentences to clips (IndicTTS or native-speaker recordings)
└── 📂 docs/BUILD.md        building the Android APK with EAS
```

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🚀 Quick start

```bash
npm install            # from the repo root (npm workspaces)
npm test               # 127 core + 39 server tests
npm run test:db        # server store against real PostGIS (embedded, ~40 s)
npm run test:gate      # just the Safety Gate proof. Show this to the jury.
npm run mobile         # start Expo; scan the QR code with Expo Go (SDK 57)
npm run server         # API on :4000. Embedded PostGIS, live Open-Meteo sea state
npm run dashboard      # officer dashboard on :5173 (set VITE_API_URL if the API is not on :4000)
```

> [!TIP]
> **Officer dashboard login:** any number (dev mode), OTP `123456`. Use **Load demo fleet** in the top bar to put 40 simulated boats on the map.

> [!NOTE]
> **Without a server, the app runs in offline demo mode.**
> - The login OTP is `123456`.
> - Data comes from the bundled Nagapattinam scenarios.
> - To use the server, run `npm run server` and set `EXPO_PUBLIC_API_URL=http://<your-PC-IP>:4000` in `apps/mobile/.env` (see `.env.example`). With the server running, the dev OTP is still `123456` until Twilio is configured.

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🎬 The 90-second demo

| # | Step | What you see |
|:-:|---|---|
| 1 | **Log in:** pick தமிழ், choose Fisherman, and enter OTP `123456` | Home screen with the big mic |
| 2 | **Ask if it's safe:** tap **"இன்று போகலாமா?"** (can I go today?) | 🟢 Green card and a spoken Tamil reply: 18 km south-east, ~24 L of diesel, start back by 4:00 PM |
| 3 | **Switch to a cyclone day:** ⚙ Settings → Demo scenario → **Cyclone day** | The scenario changes |
| 4 | **Ask again** | 🔴 Red card with the Tamil warning and the end time, *"வியாழன் மாலை 6:00 வரை"* (until Thursday 6:00 PM). The fishing answer doesn't appear, and the Zone Map is locked |
| 5 | **Show the proof:** run `npm run test:gate` | ✅ Every test passes |
| 6 | **Go offline:** turn on airplane mode and ask again | It still answers, and the data age stays visible |
| 7 | **Send an SOS** | A 10-second cancel window, then the SOS is queued with the last 6 h of trail, SMS opens, and the queue flushes when signal returns |
| 8 | **Border alarm:** ⚙ Settings → Demo boat position → **Near border** | A full-screen red alarm, siren, vibration and a spoken "turn back" until "I'm turning back" is tapped. **Across border** shows the crossed message |
| 9 | **Return reminder:** after a green answer | "Return reminder set for 4:00 PM", with 2 local notifications (30 min before, and at the time) |

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🗓️ Build phases

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','cScale0':'#E3F163','cScale1':'#E9E5FB','cScale2':'#FBE4E1','cScale3':'#EEF5C4','cScale4':'#C4BBF0','cScale5':'#F6B8AE','cScaleLabel0':'#1B1C18','cScaleLabel1':'#1B1C18','cScaleLabel2':'#1B1C18','cScaleLabel3':'#1B1C18','cScaleLabel4':'#1B1C18','cScaleLabel5':'#1B1C18'}}}%%
timeline
    title ORCA, phase by phase (all ✅ done)
    Phase 1 · Core : Safety Gate + tests : Intent parser : Trip planner : 9-language templates
    Phase 2 · Mobile : Screens 01–05 : Weather · Zone Map : Settings · Officer
    Phase 3 · At sea : IMBL border alarm : Return reminders : 5-min breadcrumb trail : Clip-first voice
    Phase 4 · Server : Express + PostGIS : Hourly ingestion : OTP · SOS relay : whisper.cpp ASR
    Phase 5 · Command : Live fleet map : SOS dispatch : 9-language broadcast : Demo fleet
    Phase 6 · Native : On-device whisper STT : Screen-off tracking : EAS APK profiles
```

| Phase | Scope | Status |
|:-:|---|:-:|
| 1 | Core: Safety Gate and tests, intent, trip planner, 9-language templates | ✅ |
| 2 | Mobile screens 01–05, plus Weather, Zone Map, Settings and Officer | ✅ |
| 3 | IMBL border alarm, return reminder notifications, 5-minute breadcrumb trail, clip-first voice pipeline | ✅ |
| 4 | Server: Express + PostGIS (embedded PGlite or Postgres), hourly ingestion (live Open-Meteo sea state, IMD/INCOIS feeds), OTP, SOS relay with family SMS, fleet and officer warnings, whisper.cpp ASR | ✅ |
| 5 | Officer dashboard (screens 06–07): live fleet map with IMBL and zones, stat cards, alert feed, SOS dispatch, per-boat SMS, 9-language broadcast that enters every Safety Gate, demo fleet | ✅ |
| 6 | Native build: on-device whisper.cpp speech-to-text (whisper.rn, one-time 57 MB model), screen-off tracking with background border alerts, EAS APK profiles | ✅ (see [`docs/BUILD.md`](docs/BUILD.md)) |

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 📦 Building the APK

This PC has no Android SDK, so the APK is built in the cloud with **EAS**. Log in once, then run one command. The full steps are in [`docs/BUILD.md`](docs/BUILD.md). Expo Go still runs everything except offline speech-to-text and tracking with the screen off.

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#EEF5C4','primaryTextColor':'#1B1C18','primaryBorderColor':'#A3C12B','lineColor':'#686B63'}}}%%
flowchart LR
    A["eas login"]:::lav --> B["eas build<br/>--profile preview"]:::lav --> C["☁️ EAS cloud build"]:::ink --> D["📦 ORCA-1.0.1.apk"]:::go --> E["📲 Install on Android"]:::lime
    classDef lav fill:#E9E5FB,stroke:#4F46E5,color:#1B1C18
    classDef lime fill:#EEF5C4,stroke:#A3C12B,color:#1B1C18
    classDef ink fill:#1B1C18,color:#E3F163,stroke:#1B1C18
    classDef go fill:#E3F163,stroke:#1B1C18,color:#1B1C18,font-weight:bold
```

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🔌 Server API

| Endpoint | Who | What |
|---|:-:|---|
| `GET /health` | 🌐 anyone | store, OTP/SMS/ASR mode, last ingestion |
| `GET /harbours`, `GET /bundle?harbour=` | 🌐 anyone | offline bundle: live sea state + warnings + PFZ zones + prices |
| `POST /auth/otp`, `POST /auth/verify` | 🌐 anyone | OTP login (Twilio Verify, dev code `123456`); officer role is allow-listed |
| `GET/PATCH /me` | 🔑 logged in | language, harbour, family contact |
| `POST /sos` | 🌐 **anyone** | never rejected, idempotent; texts the control room and the family (in the fisherman's language) |
| `POST /positions` | 🧑‍✈️ fisherman | breadcrumb upload → fleet map |
| `POST /asr` | 🌐 anyone | audio → text via whisper.cpp (503 → phone uses buttons) |
| `POST /ask` | 🌐 anyone | same core pipeline server-side (for IVR/SMS channels) |
| `GET /fleet`, `GET/PATCH /sos` | 👮 officer | boats at sea, border status, return ETA, SOS dispatch |
| `POST /broadcast`, `POST /notify` | 👮 officer | district warning (gate + SMS in each fisherman's language); text one boat |
| `GET/POST/DELETE /warnings` | 👮 officer | an officer warning enters every phone's Safety Gate |
| `POST /demo/scenario`, `POST /ingest/run` | 👮 officer | stage "date badlo", run ingestion now |

Sea state comes live from **Open-Meteo** every hour for 9 harbours, one per coastal language. IMD and INCOIS don't publish stable JSON APIs, so the server accepts one normalised feed per source; the shapes are documented in [`apps/server/src/ingest/feeds.ts`](apps/server/src/ingest/feeds.ts). If a source fails, the last good data is kept. The phone shows how old the data is, and its Safety Gate blocks once the data is 12 hours old.

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🧭 Safety principles (from the brief)

| | Principle | How ORCA does it |
|:-:|---|---|
| 🤖 | **No AI in the safety decision** | Plain `if/else` logic, deterministic and testable |
| 🔒 | **Fails closed** | Missing, unreadable or stale (older than 12 h) data blocks the fishing answer |
| 📝 | **No machine translation for safety text** | Fixed, pre-written templates in every language; native-speaker review is tracked in [`packages/core/TRANSLATIONS.md`](packages/core/TRANSLATIONS.md) |
| 📢 | **Over-triggering is acceptable, a miss is not** | Safety keywords override fishing keywords |
| ⏱️ | **The data's age is always visible** | Shown on every screen, and it turns red once it is too old to trust |
| 🗺️ | **The border line is approximate** | IMBL from the 1974/1976 agreements; swap in the official Survey of India / Coast Guard dataset before real use |

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🔊 Voice clips

Fixed safety sentences (`VOICE_KEYS` in core) play from recorded clips when they exist. Anything else, and any sentence without a clip, uses the phone's own text-to-speech.

```bash
npm run voice:export                                                  # write tools/voice/texts.json
python tools/voice/render_clips.py --models <IndicTTS checkpoints>    # render with AI4Bharat IndicTTS
npm run voice:manifest                                                # or: drop native-speaker WAVs in apps/mobile/assets/voice/<lang>/<key>.wav
```

```mermaid
%%{init: {'theme':'base','themeVariables':{'fontFamily':'Inter, Segoe UI, sans-serif','primaryColor':'#E9E5FB','primaryTextColor':'#1B1C18','primaryBorderColor':'#4F46E5','lineColor':'#686B63'}}}%%
flowchart LR
    T["Fixed sentence<br/>(VOICE_KEYS)"]:::lav --> H{"Recorded clip<br/>exists?"}
    H -- yes --> CLIP["▶️ Play IndicTTS /<br/>native-speaker clip"]:::go
    H -- no --> TTS["🗣️ Phone text-to-speech"]:::lime
    classDef lav fill:#E9E5FB,stroke:#4F46E5,color:#1B1C18
    classDef lime fill:#EEF5C4,stroke:#A3C12B,color:#1B1C18
    classDef go fill:#E3F163,stroke:#1B1C18,color:#1B1C18
```

<img src=".github/assets/divider.svg" width="100%" alt=""/>

## 🙏 Acknowledgements

[IMD](https://mausam.imd.gov.in) and [INCOIS](https://incois.gov.in) for marine warnings and PFZ advisories · [Open-Meteo](https://open-meteo.com) for live sea state · [whisper.cpp](https://github.com/ggerganov/whisper.cpp) and [whisper.rn](https://github.com/mybigday/whisper.rn) for offline speech · [AI4Bharat IndicTTS](https://github.com/AI4Bharat/Indic-TTS) for Indian-language voices · [Turf.js](https://turfjs.org) for geospatial maths.

<br/>

<div align="center">

<a href="https://orca-app-gold.vercel.app/ORCA-1.0.1.apk"><img src=".github/assets/footer.svg" alt="Jaan pehle, kamai baad me. Download ORCA." width="100%"/></a>

<sub>Made for <b>Smart India Hackathon 2026</b> · Problem Statement <b>SIH26176</b></sub>

</div>
