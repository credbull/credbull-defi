import React from "react";
import { createClient } from "@supabase/supabase-js";
import { Auth } from "@supabase/auth-ui-react";
import { ThemeSupa, ThemeMinimal} from "@supabase/auth-ui-shared";

const NEXT_PUBLIC_SUPABASE_URL = "https://sxuwxsanyzwnycrwoemc.supabase.co";
const NEXT_PUBLIC_SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4dXd4c2FueXp3bnljcndvZW1jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDI5ODcxNDgsImV4cCI6MjAxODU2MzE0OH0.kF6221zUjhyjBlbfLarhVWw0Ru1CZtIl1jhu4LBvRSs";

const supabase = createClient(
  NEXT_PUBLIC_SUPABASE_URL,
  NEXT_PUBLIC_SUPABASE_ANON_KEY
);

const EmailPassword_Page: React.FC = () => {
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <div
        style={{
          width: 400,
          justifyContent: "center",
          alignItems: "center",
        }}
      >
        <Auth
          supabaseClient={supabase}
          appearance={{ theme: ThemeSupa }}
          providers={["google", "facebook", "twitter", "discord"]}
          // theme="dark"
        />
      </div>
    </main>
  );
};

export default EmailPassword_Page;
