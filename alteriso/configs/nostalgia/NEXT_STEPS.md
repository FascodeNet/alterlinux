# nostalgia プロファイル — 次の作業メモ

linux-nost で動く i486 / 128MB / non-PAE 最小ディストリの AlterISO プロファイル。
GUI（icewm）は後回し。ビルドには読まれない走り書き。

## 構成
- `profiledef.json` — arch=i486、kernel_name=linux-nost、modules=[base, ssh-server]、cow_spacesize 256M。
- `pacman.conf.i486` / `pacman.conf.i686` — 純正 archlinux32 の `/etc/pacman.conf`（pacman パッケージ同梱）をベースに、
  core/extra/community の `Include` を archlinux32 ミラー（`mirror.archlinux32.org` 主・`de.mirror` 副）の
  `Server` へ書き換え、`Architecture` をアーキ固定、末尾に `[alterlinux-nostalgia]` を追加しただけのもの。
  arch 一致で自動選択され、素の `pacman.conf` に**マージされず完全置換**される（`profile_gen.go`）ので自己完結が必須。
  素の `pacman.conf` は選択されなくても必須のフォールバックとして残す。
  i486 コンテナで `pacman -Sy` が core/extra/community/alterlinux-nostalgia の 4 リポジトリとも同期成功済み。
- `packages.d/` — グループごとに 1 ファイル。ファイル名は任意で、`Packages()` が packages.d/ 内を全結合する:
  kernel=linux-nost、boot=syslinux、shell=sudo/nano/less、
  system=alterlinux-nostalgia-settings/dbus-daemon-units/dhcpcd/earlyoom/zram-generator。
  systemd mask・journald・sysctl は alterlinux-nostalgia-settings パッケージ側が持ち、プロファイルには置かない。
  軽い参照 dbus-daemon を使うため dbus-daemon-units を packages.d で明示指定している
  （settings の depends にすると、ビルダーに入っている dbus-broker-units と衝突するため外した）。
  カスタムモジュールは不要で、素のパッケージリストで足りる。

## やること
- [ ] **i486 ビルド対応**: docs は `arch` に x86_64 しか挙げていないが、pacman.conf.<arch> と
      archlinux32 i686 のサンプルはある。AlterISO が実際に arch=i486 をビルドできるか
      （packages.i486 を読むか、archlinux32 i486 コンテナ/devtools でのクロスビルド）を要確認。ツール側の改修が要るかも。
- [ ] **archlinux32 にパッケージがあるか確認**: alterlinux-nostalgia-settings（自前 repo）、zram-generator、earlyoom。
      無いものはパッケージ化する。dbus-daemon-units は core にあることを確認済み。
- [ ] **airootfs**: 引き継いだ root/.automated_script.sh などをレトロなライブ用に削る。ライブ用のホスト名を設定。
      ライブとインストール後で mask を揃えるため、イメージに alterlinux-nostalgia-settings を入れる。
- [ ] **installer/firstboot**: `systemctl preset-all` を走らせて 00-nost.preset
      （dhcpcd/sshd/earlyoom を enable）を適用させる。mask は勝手に効く。
- [ ] **syslinux**: BIOS 用の cfg（i486 に UEFI はない）。カーネル/initramfs 名が linux-nost と一致するか確認。
- [ ] **cow_spacesize / ライブ RAM**: ライブ起動には 128MB より多く要る。256M COW はインストーラセッション用で、
      128MB のターゲットは*インストール後*のシステム。
- [ ] **GUI は後で**: icewm モジュール（xorg-server + icewm + startx / 軽量 DM）。
- [ ] **テスト**: ISO をビルドして `qemu-system-i386 -cpu 486` で起動。
      `systemctl is-enabled systemd-resolved` が masked か、`free -h` を確認。

## メモ
- systemd の mask は alterlinux-nostalgia-settings パッケージが `/usr/lib/systemd/system/<unit> -> /dev/null`
  （ベンダーマスク）で配る。systemd 261 の実機で systemctl がこれを `masked` 扱いすること、pacman が所有すること、
  30-systemd-daemon-reload フックが preset なしで適用することを確認済み。`/etc` は汚さない。
- preset は enable/disable のみで mask はできない。別レイヤー。
- systemd-timesyncd は意図的に mask しない（古い機体は RTC 電池切れで NTP が要る）。
