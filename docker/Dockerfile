# ─────────────────────────────────────────────────────────────────────────────
# Proxmox Backup Server – ARM64 Docker Image
# ─────────────────────────────────────────────────────────────────────────────
# DEBIAN_VERSION: bookworm | trixie  (wofferl releases 用)
# PBS_VERSION   : wofferl のリリースタグ (例: 4.1.5-2)
# ─────────────────────────────────────────────────────────────────────────────
ARG DEBIAN_VERSION=trixie
FROM debian:${DEBIAN_VERSION}-slim

ARG DEBIAN_VERSION=trixie
ARG PBS_VERSION=unknown

ENV DEBIAN_FRONTEND=noninteractive

# ── 1. 基本ツールと Proxmox apt リポジトリ ──────────────────────────────────
#   アーキテクチャ非依存 (all) の Perl/JS パッケージなどを Proxmox リポジトリから
#   解決するために追加する。arm64 向けのコアバイナリは次ステップで deb を直接投入。
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
    && \
    # Proxmox 公開鍵を取得
    curl -fsSL "https://enterprise.proxmox.com/debian/proxmox-release-${DEBIAN_VERSION}.gpg" \
        -o "/etc/apt/trusted.gpg.d/proxmox-release-${DEBIAN_VERSION}.gpg" \
    && \
    # no-subscription リポジトリ (Perl ライブラリ等の依存解決に使用)
    echo "deb http://download.proxmox.com/debian/pbs ${DEBIAN_VERSION} pbs-no-subscription" \
        > /etc/apt/sources.list.d/pbs.list \
    && \
    apt-get update \
    && \
    rm -rf /var/lib/apt/lists/*

# ── 2. wofferl の arm64 deb パッケージをインストール ───────────────────────
#   ビルド時に docker/debs/ へダウンロード済みのパッケージを COPY して投入する。
#   dpkg -i で先に展開し、不足依存は apt-get -f で apt から補完する。
COPY debs/ /tmp/debs/

RUN dpkg -i /tmp/debs/*.deb 2>&1 | grep -v "^dpkg-deb:" || true && \
    apt-get install -f -y --no-install-recommends && \
    rm -rf /tmp/debs /var/lib/apt/lists/*

# ── 3. 実行環境の準備 ───────────────────────────────────────────────────────
RUN mkdir -p \
        /var/lib/proxmox-backup \
        /etc/proxmox-backup \
        /run/proxmox-backup && \
    # 不要なサービス起動スクリプトを無効化 (systemd がないため)
    find /etc/init.d /etc/rc*.d -name '*proxmox*' -delete 2>/dev/null || true

# データディレクトリはボリュームとして外部マウントを推奨
VOLUME ["/var/lib/proxmox-backup", "/etc/proxmox-backup"]

# PBS Web UI / API ポート
EXPOSE 8007

# ── 4. エントリーポイント ────────────────────────────────────────────────────
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

LABEL org.opencontainers.image.title="Proxmox Backup Server (ARM64)" \
      org.opencontainers.image.version="${PBS_VERSION}" \
      org.opencontainers.image.base.name="debian:${DEBIAN_VERSION}-slim"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
