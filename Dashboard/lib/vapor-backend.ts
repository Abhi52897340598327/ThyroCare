export type USDANutritionDetail = {
  detectedFood: string;
  estimatedGrams: number;
  usdaSearchQuery: string;
  usdaDescription: string;
  calories?: number;
  proteinGrams?: number;
  carbohydrateGrams?: number;
  fiberGrams?: number;
  sugarGrams?: number;
  fatGrams?: number;
  potassiumMilligrams?: number;
  vitaminCMilligrams?: number;
  vitaminBMilligrams?: number;
  vitaminDMicrograms?: number;
};

export type MealAnalysis = {
  name: string;
  timeLabel: string;
  confidence: number;
  protein: number;
  carbs: number;
  vitamins: number;
  produce: number;
  tshImpact: string;
  t3Impact: string;
  t4Impact: string;
  tshPercentChange: number;
  t3PercentChange: number;
  t4PercentChange: number;
  nutritionDetails: USDANutritionDetail[];
};

export type StoredMealAnalysis = {
  analysis: MealAnalysis;
  imagePath?: string;
};

function vaporBaseURL() {
  const baseURL = process.env.NEXT_PUBLIC_VAPOR_API_BASE_URL;

  if (!baseURL) {
    throw new Error("NEXT_PUBLIC_VAPOR_API_BASE_URL is not configured.");
  }

  return baseURL.replace(/\/$/, "");
}

export async function fetchHistoricalAnalyses() {
  const response = await fetch(`${vaporBaseURL()}/analyses`, {
    method: "GET",
    headers: {
      Accept: "application/json"
    },
    cache: "no-store"
  });

  if (!response.ok) {
    throw new Error(`Vapor backend returned ${response.status}.`);
  }

  return (await response.json()) as StoredMealAnalysis[];
}
