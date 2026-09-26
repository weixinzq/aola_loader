// 架构角色：项目窗口的公共视觉与基础行为基类，不承载 feature 业务逻辑。
// 数据流：派生 Form -> 一致的 WinForms 初始化和主题样式。
using System;
using System.Windows.Forms;

namespace AolaLoader.UI.Common;

/// <summary>
/// 所有窗口的轻量基类。窗口层级交给 Windows 默认激活行为和
/// ChildWindowCoordinator 管理，避免在拖动期间执行同步的置顶往返。
/// </summary>
internal abstract class AolaFormBase : Form
{
}
