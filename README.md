# P3NR V3 — GitHub Pages + Supabase

Frontend P3NR Multi Desa Kecamatan Tanjungsari.

## GitHub Pages
1. Upload the contents of this folder to the repository root.
2. Ensure `index.html` is in the repository root.
3. GitHub → Settings → Pages → Deploy from a branch → `main` → `/ (root)`.

## Supabase
The HTML is already configured with the supplied Supabase project URL and frontend publishable key.
Do not replace it with a service-role/secret key.

## Authentication
After creating an Auth user, insert the same Auth user UUID into `public.profiles` with:
- Admin Kecamatan: `role = admin_kecamatan`, `village_id = NULL`
- Petugas Desa: `role = petugas_desa`, `village_id = <assigned village UUID>`

## Important
RLS in Supabase remains the actual access control. The role selector in the HTML is only a login UX check.
