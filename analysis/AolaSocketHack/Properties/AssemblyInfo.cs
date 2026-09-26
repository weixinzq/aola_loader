// 架构角色：注入程序集元数据，允许 Verify 工程访问 internal 类型进行契约验证。
using System.Runtime.CompilerServices;

[assembly: InternalsVisibleTo("AolaSocketHack.Verify")]
