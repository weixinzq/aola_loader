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
