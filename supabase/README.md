# AI TCG Supabase Setup

The AI tabs call the `tcg-assistant` Edge Function. The function requires a signed-in Supabase user and keeps the OpenAI API key on the server.

1. Create an OpenAI API key for the project.
2. In Supabase Dashboard, open **Project Settings > Edge Functions > Secrets** and add `OPENAI_API_KEY`. Never add this key to Flutter code or commit it to the repository.
3. Install and sign in to the Supabase CLI, then link this project:

   ```powershell
   supabase login
   supabase link --project-ref mnwtomjiwlslhqfrdvpq
   ```

4. Deploy the function from the repository root:

   ```powershell
   supabase functions deploy tcg-assistant --project-ref mnwtomjiwlslhqfrdvpq
   ```

The Edge Function has JWT verification enabled. Users must sign in before calling it. OpenAI usage may incur charges; set billing limits and monitor usage in the OpenAI project.

AI explanations are informational, may be incomplete, and are not official judge rulings. Verify tournament decisions with the game's official rules or a certified judge.
