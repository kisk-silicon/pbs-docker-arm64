# pbs-docker-arm64

[wofferl/proxmox-backup-arm64](https://github.com/wofferl/proxmox-backup-arm64) のビルド済み ARM64 deb パッケージを使用した、**非公式** Proxmox Backup Server の ARM64 Docker イメージです。

> **注意**: このイメージは Proxmox VE プロジェクトおよび wofferl 氏とは無関係の非公式プロジェクトです。

## イメージタグ

| タグ | 内容 |
|---|---|
| `latest-trixie` | Trixie (Debian 13) 向け最新版 |
| `latest-bookworm` | Bookworm (Debian 12) 向け最新版 |
| `4.1.5-2-trixie` | バージョン固定タグ（例） |
| `4.1.5-2-bookworm` | バージョン固定タグ（例） |

現時点では wofferl 側が Trixie 向けビルドのみを提供しているため、`latest-trixie` のみが自動更新されます。

## クイックスタート

```bash
docker run -d \
  --name proxmox-backup \
  -p 8007:8007 \
  -v pbs-data:/var/lib/proxmox-backup \
  -v pbs-config:/etc/proxmox-backup \
  -e PBS_ADMIN_PASSWORD=yourpassword \
  ghcr.io/<owner>/pbs-docker-arm64:latest-trixie
```

ブラウザで `https://<host>:8007` を開き、`admin@pbs` / 設定したパスワードでログインしてください。

> 自己署名証明書を使用するため、初回アクセス時にブラウザの警告が表示されます。

## Docker Compose

```yaml
services:
  proxmox-backup:
    image: ghcr.io/<owner>/pbs-docker-arm64:latest-trixie
    container_name: proxmox-backup
    restart: unless-stopped
    ports:
      - "8007:8007"
    volumes:
      - pbs-data:/var/lib/proxmox-backup
      - pbs-config:/etc/proxmox-backup
    environment:
      PBS_ADMIN_PASSWORD: yourpassword
      # PBS_LOG_LEVEL: info   # error | warn | info | debug

volumes:
  pbs-data:
  pbs-config:
```

## 環境変数

| 変数名 | デフォルト | 説明 |
|---|---|---|
| `PBS_ADMIN_PASSWORD` | ランダム生成 | `admin@pbs` ユーザーの初期パスワード。未設定時は起動ログに出力されます |
| `PBS_LOG_LEVEL` | `info` | ログレベル: `error` / `warn` / `info` / `debug` |

## ボリューム

| パス | 内容 |
|---|---|
| `/var/lib/proxmox-backup` | バックアップデータストア・データベース |
| `/etc/proxmox-backup` | 設定ファイル・TLS証明書 |

データの永続化のため、両方をボリュームまたはバインドマウントしてください。

## 自動ビルドの仕組み

GitHub Actions が6時間ごとに wofferl/proxmox-backup-arm64 の新しいリリースを検知し、未ビルドのバージョンを自動的にビルドして ghcr.io にプッシュします。

```
wofferl がリリース公開
        ↓
check-releases ジョブが差分を検出
        ↓
build ジョブ (ARM64 ネイティブランナー)
  1. deb パッケージをダウンロード
  2. docker build
  3. ghcr.io にプッシュ
```

手動実行は Actions タブ → `Build ARM64 Docker Images` → `Run workflow` から行えます。`Force rebuild` オプションで既存タグを上書きできます。

## ライセンスと帰属

### このリポジトリ (Dockerfile・スクリプト)

MIT License — 詳細は [LICENSE](LICENSE) を参照してください。

### Proxmox Backup Server 本体

Proxmox Backup Server は **GNU Affero General Public License v3.0 (AGPL-3.0)** の下で配布されています。このDockerイメージに含まれるバイナリはソースコードを**無改変のまま**再パッケージしたものです。

- ソースコード: <https://git.proxmox.com/?p=proxmox-backup.git>
- ライセンス全文: <https://www.gnu.org/licenses/agpl-3.0.html>

AGPL-3.0 の条件により、このイメージを使用してネットワーク越しにサービスを提供する場合は、ユーザーがソースコードを入手できる状態にする必要があります。上記の公式リポジトリへのリンクがその要件を満たします。

### wofferl/proxmox-backup-arm64

ARM64向けビルドは [wofferl](https://github.com/wofferl/proxmox-backup-arm64) 氏によって提供されています。ビルドスクリプトには明示的なライセンスが付与されていませんが、生成される deb パッケージは上記 AGPL-3.0 の対象です。

**このイメージは Proxmox Server Solutions GmbH の公式サポート対象外です。本番環境での利用は自己責任でお願いします。**
