<!--
  README.md
  Instructions for configuring and deploying the Pomodoro Pro support page.
-->
# Pomodoro Pro — Support Page

This is a static, accessible support page for `Pomodoro Pro` designed to be published via GitHub Pages or any static host.

## Files

- `index.html` — main page (contains a meta tag `meta[name="app-version"]` with default `1.0 (4)`).
- `styles.css` — CSS styles using CSS variables for easy theming.
- `script.js` — Vanilla JS: i18n (TR/EN), form validation, Formspree submission, mailto fallback, file checks.

## Quick setup

1. Copy the `support/` folder into your repository root (already placed here).
2. Edit `script.js` and replace `CONFIG.FORMSPREE_ENDPOINT` with your Formspree endpoint (e.g. `https://formspree.io/f/{id}`) OR configure Netlify Forms by adding `data-netlify="true"` to the form and deploying to Netlify.
3. Replace `CONFIG.SUPPORT_EMAIL` with your support email (default: `support@microjasper.com`).
4. (Optional) Replace placeholder `app-icon-placeholder.png` with your app icon.

## Configurable variables

- `SUPPORT_EMAIL` — support e‑mail used in mailto fallback and copy buttons.
- `FORMSPREE_ENDPOINT` — form endpoint to accept POST requests (Formspree example).
- `PRIVACY_POLICY_URL` — update the links in `index.html`.
- CSS variables (in `styles.css` under `:root`): `--primary`, `--secondary`, `--background`, `--text`, `--muted`.

## Form behaviour

- Client-side validation checks required fields and message minimum length (20 chars).
- File attachments allowed: `.txt`, `.log`, `.json` up to 10MB. If the static host blocks file uploads (CORS), users are recommended to use the mail fallback.
- Primary submission attempts a `fetch` POST to `FORMSPREE_ENDPOINT`.
- Fallback `mailto:` option builds an email body and opens the user's mail client (attachments must be added manually).

## Accessibility

- Semantic markup (labels, aria attributes, `role=status`, `aria-live`) for screen reader announcements.
- Keyboard-accessible accordions (details/summary) and focus outlines.
- Buttons and controls have minimum touch target sizes.

## i18n

- Default language is Turkish. Toggle to English using the `EN` button in the header.
- Strings are in `script.js` DICT object for easy extension.

## Deploy to GitHub Pages

1. Commit the `support/` folder to your repository root.
2. In GitHub repo settings, enable Pages and set the source to the branch (`main`) and folder (`/support` or `/` depending on where you put the files).
3. After publishing, the Support URL will be `https://<username>.github.io/<repo>/` or `https://<username>.github.io/<repo>/support/`.

## Notes

- For production, ensure you update `FORMSPREE_ENDPOINT` and confirm CORS is supported. For more reliable uploads, consider using a server-side endpoint that accepts FormData and then forwards the data to your ticketing system.
- This page is intentionally dependency-free (no frameworks).

## Local test

To test the static page locally (recommended to use a simple HTTP server so scripts and CORS behave correctly):

```bash
# from the `support/` directory
python3 -m http.server 8000
# then open http://localhost:8000 in your browser
```

Notes:
- Serve over HTTP(S) to test Formspree POST behavior. If you open `index.html` directly via the file system (`file://`), some features (fetch/CORS) may not behave as expected.
- To test Formspree you must set `CONFIG.FORMSPREE_ENDPOINT` in `script.js` to your endpoint.
 
### Redirect / thank-you testing

To test redirect to the thank-you page after successful submission, edit `support/script.js` and set `CONFIG.REDIRECT_ON_SUCCESS` to `true` (it is `true` by default in this repo). When enabled, a successful post will redirect to `support/thank-you.html`.

Local HTTP server example (serves the `support/` directory):

```bash
python3 -m http.server 8000 --directory support
# then open http://127.0.0.1:8000/
```

Notes:
- Use DevTools → Network to inspect the POST request status and response body.
- If you want to disable redirect and only show inline confirmation, set `CONFIG.REDIRECT_ON_SUCCESS = false` and `CONFIG.SHOW_INLINE_SUCCESS = true`.
