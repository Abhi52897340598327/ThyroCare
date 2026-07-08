# ThyroCare Backend

Swift/Vapor API for meal image analysis.

## Setup

```bash
cd Backend
cp .env.example .env
```

Add your new OpenAI and USDA keys to `.env`.

Run:

```bash
swift run App serve --hostname 0.0.0.0 --port 8080
```

From iPhone, use your Mac's LAN IP:

```text
http://YOUR_MAC_IP:8080
```

## Endpoints

```text
GET /health
POST /analyze-meal
GET /dashboard
```

`POST /analyze-meal` expects:

```json
{
  "imageBase64": "...",
  "mimeType": "image/jpeg"
}
```
