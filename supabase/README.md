# AI TCG Supabase Setup

The AI tabs call the `tcg-assistant` Edge Function. The function requires a signed-in Supabase user and keeps the Gemini API key on the server.
It uses Gemini 3.5 Flash-Lite with low thinking and a concise output limit to prioritize response speed, falling back to Gemini 3.6 Flash if Flash-Lite is temporarily unavailable.

1. Create a Gemini API key in [Google AI Studio](https://aistudio.google.com/apikey). Confirm Gemini API access and usage limits for its Google project.
2. In Supabase Dashboard, open **Project Settings > Edge Functions > Secrets** and add `GEMINI_API_KEY` with the key as its value. Never add this key to Flutter code or commit it to the repository.
3. Install/sign in to the Supabase CLI, then link this project from the repository root:

   ```powershell
   npx --yes supabase login
   npx --yes supabase link --project-ref mnwtomjiwlslhqfrdvpq
   ```

4. Deploy the function from the repository root:

   ```powershell
   npx --yes supabase functions deploy tcg-assistant --remote=mnwtomjiwlslhqfrdvpq
   ```

After the Gemini function works, you may remove the old `OPENAI_API_KEY` secret if no other function uses it.

The Edge Function has JWT verification enabled. Users must sign in before calling it. Gemini API quota and billing are managed separately from ChatGPT/OpenAI; monitor usage and limits in Google AI Studio.

AI explanations are informational, may be incomplete, and are not official judge rulings. Verify tournament decisions with the game's official rules or a certified judge.
