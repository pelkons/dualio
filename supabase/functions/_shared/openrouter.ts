export type OpenRouterMessage = {
  role: "system" | "user" | "assistant";
  content:
    | string
    | Array<
      | { type: "text"; text: string }
      | { type: "image_url"; image_url: { url: string; detail?: string } }
    >;
};

export type OpenRouterStructuredResult = {
  status: "complete" | "disabled" | "failed";
  model?: string;
  json?: Record<string, unknown>;
  error?: string;
};

type OpenRouterStructuredOptions = {
  models: string[];
  messages: OpenRouterMessage[];
  schemaName: string;
  schema: Record<string, unknown>;
};

export function openRouterProviderPreferences() {
  return {
    require_parameters: true,
    allow_fallbacks: true,
    data_collection: "deny",
  };
}

export async function callOpenRouterStructuredJson(
  options: OpenRouterStructuredOptions,
): Promise<OpenRouterStructuredResult> {
  const apiKey = Deno.env.get("OPENROUTER_API_KEY");
  if (!apiKey) {
    return { status: "disabled", error: "openrouter_api_key_missing" };
  }

  const models = options.models.map((model) => model.trim()).filter(Boolean);
  if (models.length === 0) {
    return { status: "disabled", error: "openrouter_model_missing" };
  }

  let lastError = "unknown_error";
  for (const model of models) {
    try {
      const response = await fetch(
        "https://openrouter.ai/api/v1/chat/completions",
        {
          method: "POST",
          headers: {
            "authorization": `Bearer ${apiKey}`,
            "content-type": "application/json",
          },
          body: JSON.stringify({
            model,
            messages: options.messages,
            response_format: {
              type: "json_schema",
              json_schema: {
                name: options.schemaName,
                strict: true,
                schema: options.schema,
              },
            },
            provider: openRouterProviderPreferences(),
            stream: false,
          }),
        },
      );

      if (!response.ok) {
        lastError = `http_${response.status}`;
        continue;
      }

      const payload = await response.json();
      const text = extractOpenRouterContent(payload);
      const json = parseJsonObject(text);
      if (Object.keys(json).length === 0) {
        lastError = "invalid_json_response";
        continue;
      }

      return { status: "complete", model, json };
    } catch (error) {
      lastError = error instanceof Error ? error.name : "unknown_error";
    }
  }

  return { status: "failed", model: models[0], error: lastError };
}

export function parseJsonObject(value: string): Record<string, unknown> {
  const trimmed = value.trim().replace(/^```json\s*/i, "").replace(
    /^```\s*/i,
    "",
  ).replace(/```$/i, "").trim();
  const start = trimmed.indexOf("{");
  const end = trimmed.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    return {};
  }
  try {
    return JSON.parse(trimmed.slice(start, end + 1)) as Record<string, unknown>;
  } catch {
    return {};
  }
}

function extractOpenRouterContent(payload: Record<string, unknown>): string {
  const choices = payload.choices;
  if (!Array.isArray(choices) || choices.length === 0) {
    return "";
  }
  const first = choices[0];
  if (!first || typeof first !== "object") {
    return "";
  }
  const message = (first as Record<string, unknown>).message;
  if (!message || typeof message !== "object") {
    return "";
  }
  const content = (message as Record<string, unknown>).content;
  if (typeof content === "string") {
    return content;
  }
  if (!Array.isArray(content)) {
    return "";
  }
  return content.map((part) => {
    if (!part || typeof part !== "object") {
      return "";
    }
    const text = (part as Record<string, unknown>).text;
    return typeof text === "string" ? text : "";
  }).filter(Boolean).join("\n");
}
