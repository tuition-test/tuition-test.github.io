// =====================================================================
// supabase-client.js
// Initializes the Supabase JS client (loaded via CDN in HTML).
//
// ⚠️  IMPORTANT — API KEY NOTE:
// The key provided ("sb_publishable_...") is Supabase's newer publishable
// key format. The supabase-js v2 client expects a JWT anon key.
// You must retrieve the correct JWT key from:
//   Supabase Dashboard → Project Settings → API → "anon / public" key
// It looks like: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
// Replace SUPABASE_ANON_KEY below with that value.
// =====================================================================

const SUPABASE_URL = "https://pchastwhpbsvjdyivwoi.supabase.co";

// TODO: Replace with the JWT anon key from:
//  Supabase Dashboard → Project Settings → API → anon/public key
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjaGFzdHdocGJzdmpkeWl2d29pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExODk3MjUsImV4cCI6MjA5Njc2NTcyNX0.MMBPRkJ3jUqs7wDAZFB7lmnZmoYoVm1ONGEDHhtetgI";

// `supabase` global is injected by the CDN script tag present in every HTML file:
// <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
const sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    storageKey: "tuition-auth"
  }
});

// Convert a plain username into the synthetic email used for Supabase Auth.
// All auth calls use "<username>@tuition.local" internally.
function usernameToEmail(username) {
  return `${username.trim().toLowerCase()}@tuition.local`;
}
