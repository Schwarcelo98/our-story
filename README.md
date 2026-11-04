# Our Story

Private Vue app for Vero and Daniel. The frontend is hosted on GitHub Pages; Supabase provides email/password login, a shared album, and shared card progress/questions.

## Supabase setup (once)

1. Open the project's **Connect** dialog. Copy the Project URL and the publishable/anon key.
2. In **Authentication → Users**, create one user for each of you with your email and a password. In **Authentication → Providers → Email**, turn off public signups so only those accounts can log in.
3. In **SQL Editor**, run [`supabase/setup.sql`](supabase/setup.sql) once to create the tables and private photo bucket.
4. Edit the two example email addresses in [`supabase/security-hardening.sql`](supabase/security-hardening.sql) to match your two Auth accounts, then run it. This replaces the broad authenticated-user policies with a two-account allowlist and adds the album location field.
5. Under **Authentication → URL Configuration**, add the deployed GitHub Pages URL as the Site URL and an allowed Redirect URL (for example `https://YOUR_NAME.github.io/YOUR_REPOSITORY/`).

The browser uses the public anon/publishable key. Never put a `service_role` key in this frontend. The security-hardening SQL restricts database and storage access to your two Auth accounts.

### Optional login CAPTCHA

Supabase Auth already applies rate limits. To add Cloudflare Turnstile protection to the login screen, create a Turnstile widget for your GitHub Pages domain, enable CAPTCHA under **Authentication → Bot and Abuse Protection** in Supabase and enter the Turnstile secret there. Add a GitHub Actions secret named `VITE_TURNSTILE_SITE_KEY` with the widget's public site key. The login page displays the challenge when that key is configured.

## GitHub Pages deployment

1. In the GitHub repository, open **Settings → Secrets and variables → Actions** and add repository secrets named `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` with the values from Supabase.
2. Under **Settings → Pages**, choose **GitHub Actions** as the build and deployment source.
3. Push to `main` (or run the Deploy to GitHub Pages workflow manually). The workflow builds the app with the repository path and Supabase settings.

For local development, copy `.env.example` to `.env.local`, fill in those two values, then run `npm install` and `npm run dev`. Both you and Vero use the same deployed link; sign in with the two accounts created above.
