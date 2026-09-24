<p align="center"><img src="docs/screenshots/icon.png" width="96" alt=""></p>

<h1 align="center">TreeBars</h1>

<p align="center"><b>用"文件夹树 + 大小条"看清 Mac 磁盘被谁占了。</b><br>
免费、开源、不联网，支持 Dropbox 和 iCloud。</p>

<p align="center"><a href="README.md">English</a> · <a href="README.ja.md">日本語</a></p>

<p align="center"><img src="docs/screenshots/pie-zh.png" width="860" alt="TreeBars：文件夹树与饼图"></p>

## 为什么做这个

访达看不出是哪些文件夹占满了磁盘；Mac 上的磁盘分析工具大多用圆环图或矩形树图。TreeBars 采用 Windows 用户熟悉的 TreeSize 式视图：**文件夹树的每一行都有一条大小条，并显示占上级文件夹的百分比**。往下一滚，就知道该清理哪里。

## 功能

- **带大小条的文件夹树**，显示百分比，按大小排序，支持键盘操作。
- 所选文件夹的**图表**，以及**详细信息**、**扩展名**、**文件年龄**、**最大文件**、**重复文件**标签页。
- **识别云盘。** 标记 Dropbox 和 iCloud 的"仅在线"文件：它们占用云盘配额，但不占 Mac 本地空间。Dropbox 文件夹可在右键菜单中设为**不同步**。
- **"大小 / 磁盘占用"切换。** *大小*是文件本身的大小，也是云盘配额的计算依据；*磁盘占用*是在这台 Mac 上实际占用的空间。仅在线文件的磁盘占用约为 0；Docker 或虚拟机磁盘等稀疏文件可能显示 460 GB，实际只占 39 GB。
- **疑似重复文件**：大小和扩展名相同，无需下载云端文件。
- **安全：** 只移到废纸篓，且需确认；系统文件夹受保护。
- **隐私：** 不联网、无统计、无需账户。见 [PRIVACY.md](PRIVACY.md)。
- 浅色 / 深色主题，支持 9 种语言。

## 安装

需要 **macOS 14 或更高版本**，**Apple 芯片**。

1. 从 [Releases](https://github.com/gorbarov/treebars/releases) 下载 `TreeBars.zip`，解压后把 `TreeBars.app` 拖到"应用程序"。
2. 当前版本**尚未公证**，首次打开会被拦截：
   - **macOS 15 及以上：** 先打开一次并点"完成"，然后到 **系统设置 → 隐私与安全性**，点击 **仍要打开**。
   - **macOS 14：** 右键点击应用 → **打开** → **打开**。
   - 或在终端执行：`xattr -dr com.apple.quarantine /Applications/TreeBars.app`

从源码构建：`scripts/make_app.sh`（只需 Command Line Tools，无需 Xcode）。

## 它是怎么做出来的

TreeBars 也是一个实验：**代码由廉价编程模型 DeepSeek V4 Flash 编写**，Claude Opus 担任技术负责人——写需求、把工作拆成带预期答案的小任务、审查代码。模型总花费约 3 美元。详细记录见 [docs/FINDINGS.md](docs/FINDINGS.md)（俄文）。

## 参与贡献

欢迎提交 Bug、翻译，以及对现有译文的母语审校，见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可与商标

[MIT](LICENSE)。TreeBars 受 Windows 版 TreeSize 启发，但**与 JAM Software 无任何关联**。TreeSize 是 Joachim Marder e.K.（JAM Software）的注册商标。
