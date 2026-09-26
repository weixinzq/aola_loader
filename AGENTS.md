# 项目协作规则

1. **适量验证**：普通模块改动不默认新增测试，不默认执行全套测试。优先复用与改动直接相关的现有测试及必要构建；仅关键逻辑或缺陷回归确有需要时补最少测试，不编写重复实现逻辑的测试。
2. **同步模块文档**：修改模块后同步更新对应模块说明，准确记录行为、接口和限制。仅影响公共使用方式或架构时更新 README、架构文档；不为每次改动新建报告或进度文档。
3. **最小改动**：只修改任务相关内容，保留已有未提交修改，不顺带重构、格式化或清理无关代码。
4. **如实报告验证**：简短说明执行了哪些检查及结果，区分构建、自测、静态检查与真实运行；未验证的部分明确标注，不把本地提交成功等同于服务器执行成功。
5. **重要歧义先确认**：影响功能范围、行为或方案选择的歧义先询问用户；可从代码和文档确认的问题先自行核对，已确认事项不重复询问。


Keep the change minimal. Do not add validation, hash checks, file-name checks,
feature detection, compatibility guards, fallback logic, or unrelated robustness improvements.

## Reverse-engineering / asset workflow

For known game assets, SWF files, extracted resources, configuration files, and generated
asset paths, assume the project's existing paths and naming conventions are authoritative.

Do not add:
- SHA256/MD5 validation
- asset manifest verification
- filename fingerprinting
- duplicate asset detection
- generated-file integrity checks

unless specifically requested.

具体技术约束见 [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) 与 [对应模块文档](doc/modules/)。
