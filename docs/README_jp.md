
<h2 align="center">Alter Linux - 誰でも使えることを目標にした日本製でArch Linux派生のOS</h2>

<img src="../images/logo/color-black-catchcopy/AlterV6-LogowithCopy-Colored-DarkText-256px.png" alt="AlterLinux logo">

<a href="../LICENSE"><img src="https://img.shields.io/badge/LICENSE-GPL--3.0-blue?style=for-the-badge&logo=gnu" alt="License: GPLv3.0"></a>
<a href="https://www.archlinux.org/"><img src="https://img.shields.io/badge/BASE-ArchLinux-blue?style=for-the-badge&logo=arch-linux" alt="Base"></a>
<a href="https://git.archlinux.org/archiso.git/tag/?h=v43"><img src="https://img.shields.io/badge/archiso--version-43--1-blue?style=for-the-badge&logo=appveyor" alt="archiso-version"></a>
<a href="https://github.com/SereneTeam/alterlinux/releases"><img src="https://img.shields.io/github/v/release/FascodeNet/alterlinux?color=blue&include_prereleases&style=for-the-badge" alt="release"></a>

<table align="center">
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

<h2 align="center">概要</h2>

Alter LinuxはArch Linuxをベースに開発されている新しいOSです。<br>
AlterLinuxの最新の状況は[プロジェクトボード](https://github.com/orgs/FascodeNet/projects/2)を確認してください。<br>

<img src="../images/screenshot/desktop.png" alt="スクリーンショット">


<h2 align="center">特徴</h2>
<ul>
	<li>既に構築されたArchLinux環境をGUIでインストール</li>
	<li>洗練されたUIやテーマ、アイコンを搭載</li>
	<li><code>aptpac</code>で<cpde>apt</code>の構文をそのまま使用可能
	<li>archisoをベースとしたフレームワークにより簡単に派生OSを開発可能</li>
</ul>

<h2 align="center">ダウンロード</h2>
イメージファイルは<a href="https://fascode.net/projects/linux/alter/#downloads">公式サイト</a>からダウンロードできます。
<br>
<b>私達はリポジトリやイメージファイル配布のミラーサーバ提供者を探しています。</b>
<br>
もし私達にミラーを提供してくださる場合は開発者のTwitterまでお願いします。


<h2 align="center">ブランチ</h2>
主要なブランチは以下のとおりです。これ以外のブランチは一時的なものや特定の用途で使われているものです。

<table>
	<thead>
		<tr>
			<th>
				<a href="https://github.com/SereneTeam/alterlinux/tree/master">master</a>
			</th>
			<th>
				<a href="https://github.com/SereneTeam/alterlinux/tree/dev-stable">dev-stable</a>
			</th>
			<th>
				<a href="https://github.com/SereneTeam/alterlinux/tree/dev">dev</a>
			</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>
				最も安定しています。バグの修正などは遅れる場合があります。
			</td>
			<td>
				定期的に更新されます。比較的安定していて、最新の機能や修正を利用できます。
			</td>
			<td>
				常に更新されます。問題が多数残っている場合があります。
			</td>
		</tr>
	</tbody>
</table>


<h2 align="center">意見や感想について</h2>
もしAlterLinuxが起動しなかったり、使いにくかったり、標準でインストールしてほしいソフトウェアがあったら、遠慮なく<a href="https://github.com/SereneTeam/alterlinux/issues">Issues</a>に投稿して下さい。<br>
私達はAlterLinuxをより良いものにするために様々なユーザーの意見を募集しています。


<h2 align="center">ドキュメント</h2>
一部のドキュメントは情報が古かったり、一部の言語しかない場合が有ります。<br>
<ul>
	<li><a href="jp/BUILD.md">AlterLinuxをビルドする</a></li>
	<li><a href="jp/SOFTWARE.md">独自のパッケージのソースコードについて</a></li>
	<li><a href="jp/CHANNEL.md">チャンネルに関する仕様</a></li>
	<li><a href="en/PACKAGE.md">パッケージリストについての注意</a></li>
	<li><a href="jp/DOCKER.md">Docker上でビルドする方法</a></li>
	<li><a href="jp/KERNEL.md">新しいカーネルを追加する方法</a></li>
</ul>


<h2 align="center">起動できない場合</h2>
ブート時のアニメーションを無効化してブートし、ログを確認することができます。<br>
ディスクから起動し、<code>Boot Alter Linux without boot splash (x86_64)</code>を選択して下さい。<br>
また、発生した状況や機種名などを<a href="https://github.com/FascodeNet/alterlinux/issues">こちら</a>に書いて開発者に報告して下さい。


<h2 align="center">FascodeNetworkと開発者について</h2>
<a href="https://fascode.net/">Fascode Network</a>は学生を主体とする創作チームです。<br>
<a href="https://fascode.net/projects/linux/alter/">AlterLinux</a>と<a href="https://fascode.net/projects/linux/serene/">SereneLinux</a>の開発を行っています。

<h3 align="center">公式Twitterアカウント</h3>
<a href="https://twitter.com/FascodeNetwork">
	<img src="https://pbs.twimg.com/profile_images/1245716817831530497/JEkKX1XN_400x400.jpg" width="100px">
</a>
<a href="https://twitter.com/Fascode_JP">
	<img src="https://pbs.twimg.com/profile_images/1245682659231068160/Nn5tPUvB_400x400.jpg" width="100px">
</a>

<h3 align="center">開発者Twitterアカウント</h3>
<a href="https://twitter.com/Hayao0819">
	<img src="https://avatars1.githubusercontent.com/u/32128205" width="100px">
</a>
<a href="https://twitter.com/Pixel_3a">
	<img src="https://avatars0.githubusercontent.com/u/48173871" width="100px">
</a>
<a href="https://twitter.com/YangDevJP">
	<img src="https://avatars0.githubusercontent.com/u/47053316" width="100px">
</a>
<a href="https://twitter.com/yamad_linuxer">
	<img src="https://avatars1.githubusercontent.com/u/45691925" width="100px">
</a>
<a href="https://twitter.com/tukutuN_27">
	<img src="https://0e0.pw/5yuH" width="100px">
</a>
<a href="https://twitter.com/naoko1010hh">
	<img src="https://avatars1.githubusercontent.com/u/50263013" width="100px">
</a>
