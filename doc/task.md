# 任务跟踪

> 记录当前与接下来的任务；已完成事项的详细说明见 `doc/architecture.md` 与提交历史。

## 最近完成

- [x] 窗口点击置顶：所有窗口继承 `AolaFormBase`，子窗口改为非属主 `Show()`；点击哪个窗口哪个在最上层；最小化主窗口时同步隐藏/还原子窗口。
- [x] 设置持久化：主题选择、形态规则与启用开关保存到可执行文件旁的 `settings.json`（UTF-8 无 BOM）；启动时自动恢复；主题/形态变更不再自动刷新页面。
- [x] 主题“不刷新即时生效”调研：确认同一会话皮肤只拉取一次、ApplicationDomain 类冲突阻止同 ID 重载、游戏自身换肤依赖 `UiSkinStyle240927` 服务器命令、页面 JS 无刷新入口；证据存档于 `analysis/reverse-engineering/theme-live-reload-20260816/`。

## 接下来的任务

### T1. 主题即时生效：确认方案与风险（待用户决策）

目标：更换主题后不刷新页面、不发服务器命令，让游戏控制栏立即加载新皮肤。

现状约束（反编译证据）：

- `ControlBarSkinHandler._skinList` 按 ID 缓存皮肤，同一进程每个皮肤最多请求一次。
- 同进程内 `SkinN` 类已在 ApplicationDomain 定义，重拉同 URL/同类名不会产生新类，视觉不变。
- 游戏自身换肤依赖 `UiSkinStyle240927` 服务器命令，仓库规则禁止为本地资源替换发送该命令。
- 页面 JS 没有可用的 JS→Flash 皮肤刷新入口。

候选方案（均需补丁核心模块 `controlv2.swf`，风险需用户明确接受）：

- 方案 1（改动小）：即时换肤时轮换“虚拟皮肤 ID”（单数字 0..9）并跳过/清缓存，让游戏重新请求 `skin<ID>~*.swf`；限制：每会话约 9 次，与真实皮肤 ID 空间重叠。
- 方案 2（改动大）：皮肤每次加载到新 ApplicationDomain + 清缓存，同一 `SkinN` 可反复重定义；无限次切换。

共同前置：在 `controlv2` 注册 JS→Flash 触发入口（ExternalInterface），由宿主在换主题后调用。

状态：等待用户选择方案并确认接受核心模块补丁风险。

### T2. 主题即时生效：实现与验证（依赖 T1 确认）

- [ ] 保留原始 `controlv2.swf` 并记录 SHA-256，补丁产物另存于 `analysis/reverse-engineering/`。
- [ ] 按选定方案实现最小补丁（FFDec），FFDec 回读确认类/方法/实例名契约未破坏。
- [ ] 在 `AolaThemeRequestHandler`/`AolaMainForm` 增加触发调用（JS 注入 + ExternalInterface）。
- [ ] 真实 Flash 运行验证：默认无替换路径 → 替换路径 → 连续切换 → 新进程加载。
- [ ] 任何运行回归：保留候选/哈希/反编译/日志/截图，立即恢复默认路径并停止覆盖。

### T3. 设置持久化与窗口置顶的真实使用复核

- [ ] 运行 `analysis/build/AolaLoader/Release/net48/AolaLoader.exe`：切换主题确认不自动刷新且 `settings.json` 写入；重启确认主题与形态规则恢复。
- [ ] 打开抓包/对战助手/功能面板，逐一点击确认对应窗口置顶；最小化主窗口确认子窗口跟随隐藏、还原后恢复。
- [ ] 说明：此前自动化 UI 验证因 CEF 无障碍树冻结而失败，此复核以人工或非 UIA 方式完成。
