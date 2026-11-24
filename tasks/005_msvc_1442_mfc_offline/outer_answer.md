# MSVC 14.42.34433 MFC 离线包（只要 x86/x64）

## 核心结论

有，而且已经在外网把官方文件下载下来、按 SHA256 对过。

这不是 `VC_redist`。`VC_redist` 只有运行时 DLL，**编不出** MFC。编译要的是工具集下面这一棵目录：

```text
VC\Tools\MSVC\14.42.34433\atlmfc\
    include\
    lib\x86\
    lib\x64\
    src\
```

对应安装器组件（VS 2022 17.12 LTSC）：

- 组件 ID：`Microsoft.VisualStudio.Component.VC.14.42.17.12.MFC`
- 显示名：C++ v14.42 (17.12) MFC for v143 build tools (x86 & x64)
- 工具集版本：**14.42.34433**（头文件、静态库、源码都是这个版本）
- 通道：`VisualStudio.17.Release.LTSC.17.12`，清单版本 `17.12.22+37502.7`
- 清单入口：`https://aka.ms/vs/17/release.ltsc.17.12/channel`

**本包只含 x86 + x64，不含 ARM / ARM64，不含 Spectre。** 依赖闭包里本来就没有这两类，不是事后删掉的。

已核对的下载体积（34 个文件，SHA256 全部与官方清单一致）：

**285,878,341 字节 = 272.63 MiB**

注意：Visual Studio catalog 里的 `payloads[].size` 比真实文件大约 1%（清单合计写的是 289,273,253）。以 `patches/manifest.json` 里的 `size` 和 `patches/SHA256SUMS.txt` 为准，那是外网实下后的字节数。`sizeCatalog` 只是官方原字段，不要拿来比对文件长度。

解出来的库已经对上路径，例如：

- `Contents/VC/Tools/MSVC/14.42.34433/atlmfc/lib/x64/uafxcw.lib`（静态 Unicode MFC，Release，x64）
- `.../atlmfc/lib/x64/uafxcwd.lib`（Debug）
- `.../atlmfc/lib/x64/mfc140u.lib`（DLL 版 import lib）
- `.../atlmfc/include/afx.h`
- `.../atlmfc/lib/x64/atls.lib`

## 版本上必须知道的三处不一致

都在同一条 17.12 LTSC 通道里，不是下错包：

| 内容 | 版本 | 原因 |
|---|---|---|
| MFC/ATL 头文件、lib、源码 | **14.42.34433** | 就是要的工具集 |
| MFC Redist（运行 DLL：mfc140u.dll 等） | **14.42.34438** | 17.12 后续安全更新，本通道里已经没有 34433 的 redist 包 |
| `Microsoft.VC.14.42.17.12.Servicing.vsix` | **14.42.34444** | 服务元数据包，几 KB，库文件不在这里 |

如果内网机器上的 `cl.exe` 不是 14.42.34433，只拷这个 `atlmfc` 进去不能单独当编译器。本包**不含** `cl.exe` / `link.exe`。

## 包里有什么（按真实体积，大于 0.1 MiB 的）

| 文件 | 版本 | 真实大小 |
|---|---|---|
| MFC.X64.Debug.base.vsix | 14.42.34433 | 33.79 MiB |
| MFC.MBCS.X64.Debug.base.vsix | 14.42.34433 | 31.64 MiB |
| MFC.X64.base.vsix | 14.42.34433 | 31.47 MiB |
| MFC.X86.Debug.base.vsix | 14.42.34433 | 30.56 MiB |
| MFC.MBCS.X64.base.vsix | 14.42.34433 | 28.95 MiB |
| MFC.X86.base.vsix | 14.42.34433 | 28.67 MiB |
| MFC.MBCS.Debug.base.vsix | 14.42.34433 | 28.18 MiB |
| MFC.MBCS.base.vsix（x86） | 14.42.34433 | 26.08 MiB |
| MFC.Redist.X64.base.vsix | 14.42.34438 | 13.08 MiB |
| MFC.Redist.X86.base.vsix | 14.42.34438 | 12.67 MiB |
| MFC.Headers.base.vsix | 14.42.34433 | 2.29 MiB |
| MFC.Source.base.vsix | 14.42.34433 | 2.21 MiB |
| ATL.X86.base.vsix | 14.42.34433 | 0.82 MiB |
| ATL.X64.base.vsix | 14.42.34433 | 0.78 MiB |
| cab1.cab（HTML Help） | 4.74.8702.1 | 0.56 MiB |
| ATL.Headers.base.vsix | 14.42.34433 | 0.55 MiB |
| VC_HTML_Help_Workshop.msi | 4.74.8702.1 | 0.18 MiB |

另外还有约 18 个 1–10 KB 的注册用 stub vsix（`MFC.X64.vsix`、`Servicing.MFC.vsix`、`Props.ATLMFC.vsix` 等）。完整 34 个文件的 URL、SHA256、字节数在 `patches/manifest.json`。

MFC 组件在清单里还依赖 ATL 和 HTML Help Workshop，所以闭包把它们带上了。IDE 集成包 `Microsoft.VisualStudio.VC.Ide.MFC` 只在装了 VS Community/Pro/Enterprise 时才需要，Build Tools 不需要，**没有放进本包**。

## 给内网的做法（推荐：先校验，再解进现有工具集）

文件已经在仓库里，不要再下载。路径：

```text
offline/mfc-14.42.34433/parts/mfc.enc.aa … mfc.enc.ag
```

仓库是公开的，GitHub 单文件又不能超过 100MB，所以明文 vsix 没有直接提交。这 7 段是用根目录 `.secret_key` 做的 AES-256（和 `payload.enc` 同一套参数），外网已经做过整包解密回环，哈希与分片拼接一致。

在内网用 Git Bash：

```bash
bash offline/mfc-14.42.34433/unpack.sh
```

会还原出 `offline/mfc-14.42.34433/MFC1442/`（约 273 MiB，含全部 vsix、msi、cab、校验脚本）。这个目录被 gitignore，不要提交。

再验一次，不过就不要装：

```powershell
powershell -ExecutionPolicy Bypass -File offline\mfc-14.42.34433\MFC1442\verify_mfc.ps1 -Dir offline\mfc-14.42.34433\MFC1442
```

机器上**已经有** `VC\Tools\MSVC\14.42.34433`（也就是已有 cl.exe）时，把 vsix 里的 `Contents\` 解进工具集。只补 `atlmfc`，不重装 VS，也不联网：

```powershell
powershell -ExecutionPolicy Bypass -File offline\mfc-14.42.34433\MFC1442\install_atlmfc.ps1 -Dir offline\mfc-14.42.34433\MFC1442
```

脚本会先再跑一遍校验。自动找的路径包括 BuildTools / Community / Professional / Enterprise 的 `VC\Tools\MSVC\14.42.34433`。找不到就显式指定：

```powershell
.\install_atlmfc.ps1 -Dir . -ToolsetRoot "D:\VS\VC\Tools\MSVC\14.42.34433"
```

成功标志：存在

```text
<toolset>\atlmfc\lib\x64\uafxcw.lib
<toolset>\atlmfc\lib\x86\uafxcw.lib
<toolset>\atlmfc\include\afxwin.h
```

`VC_HTML_Help_Workshop.msi` 和 `cab1.cab` 不要拆进工具集。只有工程要 `hhc.exe` 时才装，且 **cab 必须和 msi 放在同一目录**：

```bat
msiexec /i VC_HTML_Help_Workshop.msi /qn /norestart
```

## 给内网的做法（备选：VS 安装器离线 layout）

只有在内网还没有 14.42.34433 工具集、必须连编译器一起装时才用这个。layout 会比 273 MiB 大很多，因为还要下 MSVC 编译器本身。必须钉死 17.12 LTSC，不能用 Current 通道（Current 现在是 14.44，对不上）。

在能上网的 Windows 上，先装过任意 VS 2022 安装器，或从 https://aka.ms/vs/17/release.ltsc.17.12/vs_buildtools.exe 下载 **17.12 通道** 的 `vs_BuildTools.exe`，然后：

```bat
vs_BuildTools.exe --layout C:\mfc1442_layout ^
  --channelUri https://aka.ms/vs/17/release.ltsc.17.12/channel ^
  --add Microsoft.VisualStudio.Component.VC.14.42.17.12.MFC ^
  --add Microsoft.VisualStudio.Component.VC.14.42.17.12.x86.x64 ^
  --lang en-US
```

不要加 `--includeRecommended`。MFC 的 recommended/optional 里会把 Spectre 和别的架构带进来。

内网安装时必须加 `--noWeb`，否则缺件时安装器会偷偷去微软 CDN：

```bat
C:\mfc1442_layout\vs_BuildTools.exe --noWeb ^
  --channelUri C:\mfc1442_layout\ChannelManifest.json ^
  --add Microsoft.VisualStudio.Component.VC.14.42.17.12.MFC ^
  --add Microsoft.VisualStudio.Component.VC.14.42.17.12.x86.x64 ^
  --wait --norestart
```

`--noWeb` 下如果 layout 缺任何一个依赖，安装会直接失败，而不是降级去联网。这是期望行为。

layout 路径不要超过 80 个字符。装完后安装器把 layout 路径记在

```text
C:\ProgramData\Microsoft\VisualStudio\Packages\_Instances\<id>\state.json
```

以后补组件还会找这个路径，不要随便挪目录。

## 不要做的事

- 不要下 `VC_redist.x64.exe` 14.42.34433。那是运行库，没有 `atlmfc`。
- 不要从 Current 通道（`aka.ms/vs/17/release`）做 layout，会变成 14.44。
- 不要只解 `MFC.X64.base.vsix`。x86、MBCS、Debug、Headers、ATL 都是闭包的一部分；少一个，对应配置就会 LNK1104。
- 不要用 catalog 里的 `size` 判断文件是否下全。哈希对、字节数等于 `manifest.json` 的 `size` 才算全。

## 给内网 AI 的提示

- 目标只是让已有的 MSVC `14.42.34433` 出现 `atlmfc`。优先跑 `verify_mfc.ps1`，通过后再跑 `install_atlmfc.ps1`。
- 不要改工具集里已有的 `bin`、`crt`、`include`（非 atlmfc）。
- 校验失败就停，不要用“大小差不多”继续解压。
- 若 `cl.exe` 版本不是 19.42 / 工具集目录不是 `14.42.34433`，不要把这套头文件混进别的工具集。
