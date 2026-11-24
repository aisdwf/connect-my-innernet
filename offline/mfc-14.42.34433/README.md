# MSVC 14.42.34433 MFC（x86 + x64）

这一目录是带进内网的完整离线包，不用再访问微软。

明文没有直接放进 Git：这个 GitHub 仓库是公开的，而且单文件不能超过 100MB。内容用仓库根目录的 `.secret_key` 做了 AES-256，再切成 7 段（每段 45MB，最后一段 2.8MB）。密钥和 `scripts/inner_pull.sh` 是同一把。

还原出来约 273MB，34 个官方文件，外网已经按 SHA256 对过。只有 x86 和 x64，没有 ARM，没有 Spectre。解开后是：

```text
VC\Tools\MSVC\14.42.34433\atlmfc\
```

不含 `cl.exe`。机器上要已经有这个工具集。

## 内网还原

用 Git Bash（和跑 `inner_pull.sh` 同一环境），在仓库根目录：

```bash
bash offline/mfc-14.42.34433/unpack.sh
```

成功后目录是 `offline/mfc-14.42.34433/MFC1442/`。这个解压结果已被 `.gitignore` 忽略，不要提交。

再校验并装进已有的 14.42.34433：

```powershell
powershell -ExecutionPolicy Bypass -File offline\mfc-14.42.34433\MFC1442\verify_mfc.ps1 -Dir offline\mfc-14.42.34433\MFC1442
powershell -ExecutionPolicy Bypass -File offline\mfc-14.42.34433\MFC1442\install_atlmfc.ps1 -Dir offline\mfc-14.42.34433\MFC1442
```

校验不过就不要装。装完应该能看到：

```text
<toolset>\atlmfc\lib\x64\uafxcw.lib
<toolset>\atlmfc\lib\x86\uafxcw.lib
<toolset>\atlmfc\include\afxwin.h
```

工具集不在默认路径时：

```powershell
.\install_atlmfc.ps1 -Dir . -ToolsetRoot "D:\VS\VC\Tools\MSVC\14.42.34433"
```

头文件和 lib 是 **14.42.34433**。MFC 运行库是同一条 17.12 通道上的 **14.42.34438**。这不是 `VC_redist`。
