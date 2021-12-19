## 注意
このモジュールを使用する際には以下のコードを`customize_airootfs.sh`に記述してください。

```bash
# Set autologin session
mkdir -p "/var/lib/AccountsService/users/"
remove "/var/lib/AccountsService/users/${username}"
cat > "/var/lib/AccountsService/users/${username}" << "EOF"
[User]
Language=
Session=<セッション名>
XSession=<セッション名>
Icon=/home/${username}/.face
SystemAccount=false
EOF
```
