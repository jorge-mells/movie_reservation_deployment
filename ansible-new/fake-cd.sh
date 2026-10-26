#!/usr/bin/env bash

set -euo pipefail
trap 'echo "An error occurred on $LINENO"' ERR

SECRET=9bf0c880f5cc2a20860b463cb55cba3401ae28034f5cec718390fc902bfc4272
PAYLOAD=$(
  cat <<'EOF'
{
  "package": {
    "package_version": {
      "container_metadata": {
        "tag": {
          "digest": "sha256:3c812ec4a3da27a4e6390068770be5a19b04fc7e3ba136ae5ae93cfdece28ce7"
        }
      }
    }
  }
}
EOF
)
SIG=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

curl -X POST http://api.example.com/hooks/deploy \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=${SIG}" \
  -H "X-GitHub-Event: push" \
  -d "$PAYLOAD"
