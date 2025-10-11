## 注意
このモジュールを使用する際には以下を`airootfs.any/etc/lightdm/lightdm.conf.d/02-autologin-session.conf`に書いてください。

```properties
[Seat:*]
autologin-session=<セッション名>
```
