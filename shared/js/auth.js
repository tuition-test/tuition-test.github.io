// =====================================================================
// auth.js
// Authentication helper functions: login, register, logout, session,
// profile fetching, and route guarding.
// Requires supabase-client.js to be loaded first.
// =====================================================================

const Auth = {
  // ---------------------------------------------------------------
  // Register a new "Other Student"
  // ---------------------------------------------------------------
  async register({ name, mobile, email, username, password }) {
    username = username.trim().toLowerCase();

    // Check username uniqueness first
    const { data: existing } = await sb
      .from("profiles")
      .select("id")
      .eq("username", username)
      .maybeSingle();

    if (existing) {
      throw new Error("Username already taken. Please choose another.");
    }

    const fakeEmail = usernameToEmail(username);

    const { data, error } = await sb.auth.signUp({
      email: fakeEmail,
      password
    });

    if (error) throw error;

    // Insert profile row
    const { error: profileErr } = await sb.from("profiles").insert({
      auth_id: data.user.id,
      name,
      mobile,
      email: email || null,
      username,
      role: "other_student",
      status: "active"
    });

    if (profileErr) throw profileErr;

    return data;
  },

  // ---------------------------------------------------------------
  // Login with username + password
  // ---------------------------------------------------------------
  async login(username, password) {
    username = username.trim().toLowerCase();
    const fakeEmail = usernameToEmail(username);

    const { data, error } = await sb.auth.signInWithPassword({
      email: fakeEmail,
      password
    });

    if (error) {
      throw new Error("Invalid username or password.");
    }

    const profile = await this.getProfile();

    if (profile && profile.status === "inactive") {
      await sb.auth.signOut();
      throw new Error("Your account has been deactivated. Contact admin.");
    }

    return { session: data.session, profile };
  },

  // ---------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------
  async logout() {
    await sb.auth.signOut();
    window.location.href = getBasePath() + "index.html";
  },

  // ---------------------------------------------------------------
  // Get current session
  // ---------------------------------------------------------------
  async getSession() {
    const { data } = await sb.auth.getSession();
    return data.session;
  },

  // ---------------------------------------------------------------
  // Get current user's profile row
  // ---------------------------------------------------------------
  async getProfile() {
    const { data: userData } = await sb.auth.getUser();
    if (!userData || !userData.user) return null;

    const { data, error } = await sb
      .from("profiles")
      .select("*")
      .eq("auth_id", userData.user.id)
      .maybeSingle();

    if (error) {
      console.error("getProfile error:", error);
      return null;
    }
    return data;
  },

  // ---------------------------------------------------------------
  // Route guard: redirect to login if not authenticated,
  // or to correct portal if role mismatch.
  // requiredRole: 'admin' | 'tuition_student' | 'other_student' | null (any)
  // ---------------------------------------------------------------
  async guard(requiredRole = null) {
    const session = await this.getSession();
    const base = getBasePath();

    if (!session) {
      window.location.href = base + "index.html";
      return null;
    }

    const profile = await this.getProfile();

    if (!profile) {
      await sb.auth.signOut();
      window.location.href = base + "index.html";
      return null;
    }

    if (profile.status === "inactive") {
      await sb.auth.signOut();
      window.location.href = base + "index.html?deactivated=1";
      return null;
    }

    if (requiredRole && profile.role !== requiredRole) {
      // redirect to their correct portal
      if (profile.role === "admin") {
        window.location.href = base + "admin/index.html";
      } else if (profile.role === "tuition_student") {
        window.location.href = base + "student/index.html";
      } else {
        window.location.href = base + "other/index.html";
      }
      return null;
    }

    return profile;
  },

  // ---------------------------------------------------------------
  // Admin: reset a user's password
  // Note: Supabase JS client (anon key) cannot directly change another
  // user's auth password without admin privileges. This uses a
  // workaround: admin must use Supabase Dashboard or a server-side
  // function for true password resets. For this no-backend setup,
  // we store a "temp password reset request" flag, OR (recommended)
  // the admin uses the Supabase Dashboard's Auth > Users > Reset
  // Password feature manually.
  //
  // For a fully client-side approach within RLS limits, we provide
  // `requestPasswordReset` which flags must_change_password = true
  // and admin communicates the new password to the student manually
  // (offline) after updating it via Dashboard, OR the simpler
  // self-service: student logs in with old password & sets new one
  // via "Change Password" in profile settings.
  // ---------------------------------------------------------------
  async flagMustChangePassword(profileId) {
    const { error } = await sb
      .from("profiles")
      .update({ must_change_password: true })
      .eq("id", profileId);
    if (error) throw error;
  },

  // ---------------------------------------------------------------
  // Change own password (self-service)
  // ---------------------------------------------------------------
  async changePassword(newPassword) {
    const { error } = await sb.auth.updateUser({ password: newPassword });
    if (error) throw error;

    // Clear must_change_password flag
    const profile = await this.getProfile();
    if (profile) {
      await sb
        .from("profiles")
        .update({ must_change_password: false })
        .eq("id", profile.id);
    }
  }
};

// ---------------------------------------------------------------------
// Determine base path so links work both on GitHub Pages
// (https://user.github.io/repo/) and locally.
// Looks for a meta tag <meta name="base-path" content="../"> in the
// page, or defaults to "./".
// ---------------------------------------------------------------------
function getBasePath() {
  const meta = document.querySelector('meta[name="base-path"]');
  return meta ? meta.getAttribute("content") : "./";
}
