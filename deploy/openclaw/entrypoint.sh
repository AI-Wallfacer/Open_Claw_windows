#!/bin/sh
set -e

CFG="$HOME/.openclaw/openclaw.json"
MDL="$HOME/.openclaw/agents/main/agent/models.json"
AUTH="$HOME/.openclaw/agents/main/agent/auth.json"

inject_json() {
  local file="$1" expr="$2"
  shift 2
  if [ -f "$file" ]; then
    tmp=$(mktemp)
    jq "$@" "$expr" "$file" > "$tmp" && mv "$tmp" "$file"
  fi
}

if [ -n "$SELF_API_KEY" ] && [ -f "$CFG" ]; then
  # 濞撳懘娅庨崣顖濆厴濞堝鏆€閻ㄥ嫭妫ら弫?auth 鐎涙顔?  inject_json "$CFG" 'del(.models.providers.self.auth) | del(.models.providers.self2.auth)'

  inject_json "$CFG" \
    '.models.providers.self.apiKey=$k | .models.providers.self.baseUrl=$u' \
    --arg k "$SELF_API_KEY" --arg u "$SELF_API_URL"

  inject_json "$MDL" \
    '.providers.self.apiKey=$k | .providers.self.baseUrl=$u' \
    --arg k "$SELF_API_KEY" --arg u "$SELF_API_URL"

  if [ -n "$SELF_API_KEY_2" ]; then
    inject_json "$CFG" \
      '.models.providers.self2.apiKey=$k | .models.providers.self2.baseUrl=$u' \
      --arg k "$SELF_API_KEY_2" --arg u "$SELF_API_URL"

    inject_json "$MDL" \
      '.providers.self2.apiKey=$k | .providers.self2.baseUrl=$u' \
      --arg k "$SELF_API_KEY_2" --arg u "$SELF_API_URL"
  fi

  if [ -n "$SELF_API_KEY_2" ]; then
    printf '{"self":"%s","self2":"%s"}\n' "$SELF_API_KEY" "$SELF_API_KEY_2" > "$AUTH"
  else
    printf '{"self":"%s"}\n' "$SELF_API_KEY" > "$AUTH"
  fi
fi

if [ -n "$FEISHU_APP_ID" ] && [ -f "$CFG" ]; then
  inject_json "$CFG" \
    '.channels.feishu.appId=$id | .channels.feishu.appSecret=$sec' \
    --arg id "$FEISHU_APP_ID" --arg sec "$FEISHU_APP_SECRET"
fi

if [ -n "$OPENCLAW_GATEWAY_TOKEN" ] && [ -f "$CFG" ]; then
  inject_json "$CFG" \
    '.gateway.auth.token=$t' \
    --arg t "$OPENCLAW_GATEWAY_TOKEN"
fi

exec "$@"
