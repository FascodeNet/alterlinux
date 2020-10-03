
<h2 align="center">Alter Linux - 誰でも使えることを目標にした日本製でArch Linux派生のOS</h2>

<p align="center">
	<img src="../images/logo/color-black-catchcopy/AlterV6-LogowithCopy-Colored-DarkText-256px.png" alt="Alter Linux logo">
</p>
<p align="center">
	<a href="https://fascode.net/en/projects/linux/alter/">
		<img src="https://img.shields.io/badge/Maintained%3F-Yes-green?style=for-the-badge">
	</a>
	<a href="../LICENSE">
		<img src="https://img.shields.io/github/license/FascodeNet/alterlinux?style=for-the-badge" alt="License: GPLv3.0">
	</a>
	<a href="https://www.archlinux.org/">
		<img src="https://img.shields.io/badge/BASE-ArchLinux-blue?style=for-the-badge&logo=arch-linux" alt="Base">
	</a>
	<a href="https://gitlab.archlinux.org/archlinux/archiso/-/tree/v48">
		<img src="https://img.shields.io/badge/archiso--version-48--1-blue?style=for-the-badge&logo=arch-linux" alt="archiso-version">
	</a>
</p>
<p align="center">
	<a href="https://travis-ci.com/github/FascodeNet/alterlinux">
		<img src="https://img.shields.io/travis/com/FascodeNet/alterlinux?style=for-the-badge">
	</a>
	<a href="https://github.com/FascodeNet/alterlinux/issues">
		<img src="https://img.shields.io/github/issues/FascodeNet/alterlinux?color=violet&style=for-the-badge&logo=github" alt="Issues">
	</a>
	<a href="https://github.com/FascodeNet/alterlinux/stargazers">
		<img src="https://img.shields.io/github/stars/FascodeNet/alterlinux?color=yellow&style=for-the-badge&logo=github">
	</a>
	<a href="https://github.com/FascodeNet/alterlinux/network/members">
		<img src="https://img.shields.io/github/forks/FascodeNet/alterlinux?style=for-the-badge">
	</a>
</p>
<p align="center">
	<a href="https://github.com/FascodeNet/alterlinux/releases">
		<img src="https://img.shields.io/github/v/release/FascodeNet/alterlinux?color=blue&include_prereleases&style=for-the-badge" alt="release">
	</a>
	<a href="https://fascode.net/en/projects/linux/alter/downloads/">
		<img src="https://img.shields.io/github/downloads/FascodeNet/alterlinux/total?style=for-the-badge">
	</a>
	<a href="https://github.com/FascodeNet/alterlinux/commits/">
		<img src="https://img.shields.io/github/last-commit/FascodeNet/alterlinux?style=for-the-badge">
	</a>
</p>

<table>
	<thead>
		<tr>
			<th style="text-align:center">
				<a href="README_jp.md">日本語</a>
			</th>
			<th style="text-align:center">
				<a href="README.md">English</a>
			</th>
		</tr>
	</thead>
</table>

<h2>〈概要〉</h2>

Alter LinuxはArch Linuxをベースに開発されている新しいOSです。<br>
Alter Linuxの最新の開発状況は<a href="https://github.com/orgs/FascodeNet/projects/2">プロジェクトボード</a>を確認してください。<br>
ユーザ向けのアナウンスや不具合等の情報は<a href="https://fascode.net/projects/linux/alter/">公式サイト</a>をご覧ください。

<h3>Xfce</h3>
<img src="../images/screenshot/desktop-xfce.png" alt="screenshot">

<h3>Lxde</h3>
<img src="../images/screenshot/desktop-lxde.png" alt="screenshot">

<h3>Cinnamon</h3>
<img src="../images/screenshot/desktop-cinnamon.png" alt="screenshot">

<h3>i3wm</h3>
<img src="../images/screenshot/desktop-i3wm.png" alt="screenshot">

<h2>〈特徴〉</h2>
<ul>
	<li>既に構築されたArch Linux環境をGUIでインストールできます</li>
	<li>64bitだけでなく、32bit(i686)もリリースしています</li>
	<li>32bit版はPAE（物理アドレス拡張）を必要としません。</li>
	<li>既に完全に日本語化されており、インストールしてすぐに日本語入力を使用できます</li>
	<li>デフォルトでZENカーネルを採用</li>
	<li>洗練されたUIやテーマ、アイコンを搭載しています</li>
	<li><code>aptpac</code>で<cpde>apt</code>の構文をそのまま使用できます</li>
	<li>archisoをベースとしたフレームワークにより簡単に派生OSを開発できます</li>
</ul>

<h2>〈ダウンロード〉</h2>
イメージファイルは<a href="https://fascode.net/projects/linux/alter/#downloads">公式サイト</a>からダウンロードできます。
<br>
<b>私達はリポジトリやイメージファイル配布用のミラーサーバ提供者を募集しております。</b>
<br>
もし私達にミラーを提供して頂ける場合は開発者のTwitterまでお願いします。


<h2>〈ブランチ〉</h2>
主要なブランチは以下のとおりです。これ以外のブランチは一時的なものや特定の用途で使われているものです。

<table>
	<thead>
		<tr>
			<th>
				<a href="https://github.com/FascodeNet/alterlinux/tree/master">master</a>
			</th>
			<th>	
				<a href="https://github.com/FascodeNet/alterlinux/tree/stable">stable</a>
			</th>
			<th>
				<a href="https://github.com/FascodeNet/alterlinux/tree/dev-stable">dev-stable</a>
			</th>
			<th>
				<a href="https://github.com/FascodeNet/alterlinux/tree/dev">dev</a>
			</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>
				最も安定しています。バグの修正などは遅れる場合があります。
			</td>
			<td>
				リリース候補です。ほとんどのバグが修正されています。
			</td>
			<td>
				定期的に更新されます。比較的安定していて、最新の機能や修正を利用できます。*
			</td>
			<td>
				常に更新されます。問題が多数残っている場合があります。
			</td>
		</tr>
	</tbody>
</table>


<h2>〈意見や感想について〉</h2>
もしAlter Linuxが起動しない、使いにくい、標準でインストールしてほしいソフトウェアがある、など意見がございましたらどうぞ遠慮なく<a href="https://github.com/FascodeNet/alterlinux/issues">Issues</a>まで意見をお寄せください。<br>
私達はAlter Linuxをより良いものにするために様々なユーザーの意見を募集しています。<br>

<h2>〈バグ報告やプルリクエストを送る際は〉</h2>
必ず<a href="CONTRIBUTING.md">CONTRIBUTING.md</a>を読んでください。


<h2>〈ドキュメント〉</h2>
一部のドキュメントは情報が古かったり、一部の言語しかない場合が有ります。<br>
また、全てのドキュメントは<code>docs</code>ディレクトリにあります。<br>
もし誤字脱字や実際と異なる表記を見つけた場合はIssuesで報告して下さい。<br>
<ul>
	<li><a href="jp/BUILD.md">Alter Linuxをビルドする</a></li>
	<li><a href="jp/SOFTWARE.md">独自のパッケージのソースコードについて</a></li>
	<li><a href="jp/CHANNEL.md">チャンネルに関する仕様</a></li>
	<li><a href="jp/PACKAGE.md">パッケージリストについての注意</a></li>
	<li><a href="jp/DOCKER.md">Docker上でビルドする方法</a></li>
	<li><a href="jp/KERNEL.md">新しいカーネルを追加する方法</a></li>
	<li><a href="jp/CONFIG.md">ビルドの設定ファイルについて</a></li>
	<li><a href="jp/CHANNEL_2_to_3.md">AlterISO2のチャンネルを3に対応させる</a></li>
	<li><a href="ja/arch-pkgbuild-parser.md">arch-pkgbuild-parserについて</a></li>
</ul>


<h2>〈起動できない場合〉</h2>
ブート時のアニメーションを無効化してブートし、ログを確認することができます。<br>
ディスクから起動し、<code>Boot Alter Linux without boot splash (x86_64)</code>を選択して下さい。<br>
また、発生した状況や機種名などを記載の上<a href="https://github.com/FascodeNet/alterlinux/issues">こちら</a>までご報告をお願いします。


<h2>〈FascodeNetworkと開発者について〉</h2>
<a href="https://fascode.net/">Fascode Network</a>は学生を主体とする創作チームです。<br>
<a href="https://fascode.net/projects/linux/alter/">Alter Linux</a>と<a href="https://fascode.net/projects/linux/serene/">SereneLinux</a>の開発を行っています。

<h3>公式Twitterアカウント</h3>
<a href="https://twitter.com/FascodeNetwork">
	<img src="https://pbs.twimg.com/profile_images/1245716817831530497/JEkKX1XN_400x400.jpg" width="100px">
</a>
<a href="https://twitter.com/Fascode_JP">
	<img src="https://pbs.twimg.com/profile_images/1245682659231068160/Nn5tPUvB_400x400.jpg" width="100px">
</a>

<h3>開発者Twitterアカウント</h3>
<a href="https://twitter.com/Hayao0819">
	<img src="https://avatars1.githubusercontent.com/u/32128205" width="100px">
</a>
<a href="https://twitter.com/Pixel_3a">
	<img src="https://avatars0.githubusercontent.com/u/48173871" width="100px">
</a>
<a href="https://twitter.com/yangniao23">
	<img src="https://avatars0.githubusercontent.com/u/47053316" width="100px">
</a>
<a href="https://twitter.com/Watasuke102">
	<img src="https://avatars3.githubusercontent.com/u/36789813" width="100px">
</a>
<a href="https://twitter.com/kokkiemouse">
	<img src="https://avatars0.githubusercontent.com/u/39451248" width="100px">
</a>
<a href="https://twitter.com/stmkza">
	<img src="https://avatars2.githubusercontent.com/u/15907797" width="100px">
</a>
<a href="https://twitter.com/yamad_linuxer">
	<img src="https://avatars1.githubusercontent.com/u/45691925" width="100px">
</a>
<a href="https://twitter.com/tukutun27">
	<img src="https://pbs.twimg.com/profile_images/1278526049903497217/CGMY5KUr.jpg" width="100px">
</a>
<a href="https://twitter.com/naoko1010hh">
	<img src="https://avatars1.githubusercontent.com/u/50263013" width="100px">
</a>
