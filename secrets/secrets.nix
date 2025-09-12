# Define which keys can decrypt which secrets
let
  # Your development machine key
  yourKey = "ssh-ed25519 AAAAC3... you@machine";

  # GitHub Actions deploy key (create with ssh-keygen)
  ciKey = "ssh-ed25519 AAAAC3... ci@github-actions";
in
{
  # Analytics ID (e.g., Google Analytics, Plausible)
  "secrets/analytics-id.age".publicKeys = [ yourKey ciKey ];

  # Custom domain for CNAME
  "secrets/custom-domain.age".publicKeys = [ yourKey ciKey ];

  # API keys for build-time data fetching
  "secrets/api-key.age".publicKeys = [ yourKey ciKey ];
}
