<h2>Alter Linux - Arch Linux-derived OS made in Japan aimed at anyone to use</h2>

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
    <a href="https://gitlab.archlinux.org/archlinux/archiso/-/tree/v46">
        <img src="https://img.shields.io/badge/archiso--version-46--1-blue?style=for-the-badge&logo=arch-linux" alt="archiso-version">
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

<b>
    日本語版は<a href="README_jp.md">こちら</a>にあります
</b>

<h2>〈Overview〉</h2>

Alter Linux is a new OS developed based on Arch Linux.<br>
Check the <a href="https://github.com/orgs/FascodeNet/projects/2">project board</a> for the latest status of Alter Linux.<br>
Please see the <a href="https://fascode.net/projects/linux/alter/">official website</a> for information on announcements and bugs for users.

<h3>Xfce</h3>
<img src="../images/screenshot/desktop-xfce.png" alt="screenshot">

<h3>Lxde</h3>
<img src="../images/screenshot/desktop-lxde.png" alt="screenshot">

<h3>Cinnamon</h3>
<img src="../images/screenshot/desktop-cinnamon.png" alt="screenshot">

<h3>i3wm</h3>
<img src="../images/screenshot/desktop-i3wm.png" alt="screenshot">

<h2>〈Feature〉</h2>
<ul>
    <li>You can install the already built Arch Linux environment with GUI</li>
    <li>We release not only 64bit but also 32bit version.</li>
    <li>The 32-bit version does not require PAE (Physical Address Extension).</li>
    <li>Adopt ZEN kernel by default</li>
    <li>Equipped with sophisticated UI, themes, and icons</li>
    <li>You can use the syntax of <code>apt</code> with <code>aptpac</code></li>
    <li>Easy development of derived OS by framework based on archiso</li>
</ul>

<h2>〈Download〉</h2>
The image file can be downloaded from the official <a href="https://fascode.net/projects/linux/alter/#downloads">website</a>.
<br>
<b>We are looking for a mirror server provider for repositories and image file distribution.</b>
<br>
If you would like us to provide a mirror please contact the developer's Twitter.

<h2>〈Branch〉</h2>
These are a list of major branches. Other branches are temporary or used for specific purposes.

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
            <th>
                <a href="https://github.com/FascodeNet/alterlinux/tree/alteriso-3-mainline">alteriso-3-mainline</a>
            </th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>
                Most stable. Bug fixes may be delayed.
            </td>
            <td>
                Release candidate. Most bugs have been fixed.
            </td>
            <td>
                It is updated regularly. Relatively stable, with the latest features and fixes. *
            </td>
            <td>
                Always updated. There may be many issues left.
            </td>
            <td>
                Next-generation AlterISO and new desktop environment are being developed.
            </td>
        </tr>
    </tbody>
</table>

<h2>〈About opinion and impression〉</h2>
If Alter Linux doesn't start, is hard to use, or has any software you want installed by default, feel free to post it to <a href="https://github.com/FascodeNet/alterlinux/issues">Issues</a>.<br>
We are soliciting opinions from various users to make Alter Linux better.<br>

<h2>〈When submitting a bug report or pull request〉</h2>
Be sure to read <a href="CONTRIBUTING.md">CONTRIBUTING.md</a>.

<h2>〈Documents〉</h2>
Some documents may have outdated information or only some languages.<br>
All documentation can be found in <code>docs</code>.<br>
If you find a typographical error or a notation that isn't the case, please report it on Issues.<br>
<ul>
	<li><a href="en/BUILD.md">Build Alter Linux</a></li>
	<li><a href="en/SOFTWARE.md">About the source code of your own package</a></li>
	<li><a href="en/CHANNEL.md">Channel specifications</a></li>
	<li><a href="en/PACKAGE.md">Notes on package list</a></li>
	<li><a href="en/DOCKER.md">How to build on Docker</a></li>
	<li><a href="en/KERNEL.md">How to add a new kernel</a></li>
	<li><a href="en/CONFIG.md">About build configuration file</a></li>
	<li><a href="en/arch-pkgbuild-parser.md">About arch-pkgbuild-parser</a></li>
</ul>

<h2>〈If you cannot start〉</h2>
You can disable the boot animation and boot to see the logs.<br>
Boot from the disk and select <code>Boot Alter Linux without boot splash (x86_64)</code>.<br>
In addition, please write down the situation and model name <a href="https://github.com/FascodeNet/alterlinux/issues">here</a>, and report it to the developer.

<h2>〈About FascodeNetwork and developers〉</h2>
<a href="https://fascode.net/">Fascode Network</a> is a creative team mainly composed of students.<br>
We are developing <a href="https://fascode.net/projects/linux/alter/">Alter Linux</a> and <a href="https://fascode.net/projects/linux/serene/">SereneLinux</a>.

<h3>Official Twitter account</h3>
<a href="https://twitter.com/FascodeNetwork">
    <img src="https://pbs.twimg.com/profile_images/1245716817831530497/JEkKX1XN_400x400.jpg" width="100px">
</a>
<a href="https://twitter.com/Fascode_JP">
    <img src="https://pbs.twimg.com/profile_images/1245682659231068160/Nn5tPUvB_400x400.jpg" width="100px">
</a>

<h3>Developer Twitter account</h3>
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
