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
#   ダウンロード済みの deb からローカル apt リポジトリを作成し、
#   Proxmox オンラインリポジトリと合わせて apt に依存関係を一括解決させる。
#   (dpkg -i + apt-get -f では apt がローカル deb 間の依存を認識できず、
#    解決不能と判断したパッケージを削除して rc 状態にしてしまうため使用しない)
COPY debs/ /tmp/debs/

RUN apt-get install -y --no-install-recommends dpkg-dev \
    && cd /tmp/debs \
    # ローカルリポジトリの Packages インデックスを生成
    && dpkg-scanpackages -m . > Packages \
    && echo "deb [trusted=yes] file:///tmp/debs ./" \
         > /etc/apt/sources.list.d/local-debs.list \
    && apt-get update \
    # arm64 バイナリは local-debs から、arch:all の Perl/JS 等は Proxmox リポジトリから解決
    && apt-get install -y --no-install-recommends proxmox-backup-server \
    # 作業用パッケージとローカルリポジトリ設定を削除
    && apt-get purge -y --autoremove dpkg-dev \
    && rm -f /etc/apt/sources.list.d/local-debs.list \
    && rm -rf /tmp/debs /var/lib/apt/lists/*

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
