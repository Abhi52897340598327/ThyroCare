# ThyroCare Backend

Swift/Vapor API for meal image analysis.

## Setup

```bash
cd Backend
cp .env.example .env
```

Add your Gemini and USDA keys to `.env`. OpenAI is optional fallback if configured.

```bash
GEMINI_API_KEY=your_key_here
GEMINI_MODEL=gemini-3.5-flash
USDA_API_KEY=your_key_here
```

Meal photos are classified with the multimodal `gemini-3.5-flash` model before USDA FoodData Central lookup.

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
GET /analyses
```

`POST /analyze-meal` expects:

```json
{
  "imageBase64": "...",
  "mimeType": "image/jpeg"
}
```
