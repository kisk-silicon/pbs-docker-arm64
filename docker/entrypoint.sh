#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Proxmox Backup Server – Docker エントリーポイント
#
# 環境変数:
#   PBS_ADMIN_PASSWORD  - admin@pbs ユーザーの初期パスワード (未設定時はランダム生成)
#   PBS_LOG_LEVEL       - ログレベル: error|warn|info|debug (デフォルト: info)
# ─────────────────────────────────────────────────────────────────────────────
set -eo pipefail

CFG_DIR=/etc/proxmox-backup
DATA_DIR=/var/lib/proxmox-backup
RUN_DIR=/run/proxmox-backup

# ── ディレクトリ確保 ─────────────────────────────────────────────────────────
mkdir -p "$CFG_DIR" "$DATA_DIR" "$RUN_DIR"

# ── 初回起動: 設定ファイルの初期化 ───────────────────────────────────────────
if [ ! -f "$CFG_DIR/user.cfg" ]; then
    echo "==> Initializing Proxmox Backup Server configuration ..."

    # datastore.cfg (空で OK、後から proxmox-backup-manager で追加)
    touch "$CFG_DIR/datastore.cfg"

    # admin@pbs ユーザーを作成
    ADMIN_PASS="${PBS_ADMIN_PASSWORD:-$(openssl rand -base64 16)}"

    proxmox-backup-manager user create admin@pbs \
        --comment "Docker admin user" \
        --password "$ADMIN_PASS" 2>/dev/null || true

    # admin@pbs に管理者ロールを付与
    proxmox-backup-manager acl update / Admin \
        --auth-id "admin@pbs" 2>/dev/null || true

    if [ -z "${PBS_ADMIN_PASSWORD:-}" ]; then
        echo "======================================================"
        echo " Generated admin@pbs password: $ADMIN_PASS"
        echo " Set PBS_ADMIN_PASSWORD env var to use a fixed password"
        echo "======================================================"
    fi
fi

# ── TLS 証明書の生成 (存在しない場合) ───────────────────────────────────────
CERT_FILE="$CFG_DIR/proxy.pem"
KEY_FILE="$CFG_DIR/proxy.key"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "==> Generating self-signed TLS certificate ..."
    openssl req -x509 -newkey rsa:4096 -sha256 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -days 3650 \
        -nodes \
        -subj "/CN=proxmox-backup-docker" \
        -addext "subjectAltName=IP:0.0.0.0" \
        2>/dev/null
    chmod 600 "$KEY_FILE"
fi

# ── ログレベルの設定 ──────────────────────────────────────────────────────────
LOG_LEVEL="${PBS_LOG_LEVEL:-info}"

echo "==> Starting proxmox-backup-proxy (log-level: $LOG_LEVEL) ..."

# proxmox-backup-proxy を直接起動 (systemd 不要)
exec proxmox-backup-proxy --log-level "$LOG_LEVEL"
