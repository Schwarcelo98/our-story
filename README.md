# Our Story

Private Vue app for Vero and Daniel. The frontend is hosted on GitHub Pages; Supabase provides email/password login, a shared album, and shared card progress/questions.

## Supabase setup (once)

1. Create a Supabase project and open **Project Settings → API**. Copy the Project URL and the publishable/anon key.
2. In **Authentication → Users**, create one user for each of you with your email and a password. In **Authentication → Providers → Email**, turn off public signups so only those accounts can log in.
3. In **SQL Editor**, run [`supabase/setup.sql`](supabase/setup.sql) once. This creates the memories and shared progress tables, a private photo bucket, and authenticated-only row/storage policies.
4. Under **Authentication → URL Configuration**, add the deployed GitHub Pages URL as the Site URL and an allowed Redirect URL (for example `https://YOUR_NAME.github.io/YOUR_REPOSITORY/`).

The browser uses the public anon/publishable key. Never put a `service_role` key in this frontend. Database and storage access are restricted by Supabase RLS to signed-in accounts.

## GitHub Pages deployment

1. In the GitHub repository, open **Settings → Secrets and variables → Actions** and add repository secrets named `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` with the values from Supabase.
2. Under **Settings → Pages**, choose **GitHub Actions** as the build and deployment source.
3. Push to `main` (or run the Deploy to GitHub Pages workflow manually). The workflow builds the app with the repository path and Supabase settings.

For local development, copy `.env.example` to `.env.local`, fill in those two values, then run `npm install` and `npm run dev`. Both you and Vero use the same deployed link; sign in with the two accounts created above.
