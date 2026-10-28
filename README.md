# MoonGrade

**MoonBit 作业评测与学习反馈平台。**

MoonGrade 把 MoonBit 编译检查、测试、自定义命令和评分规则组织成可重复的作业评测流程。教师可以一次批改多个学生项目，学生可以得到按检查项拆分的得分、失败原因和下一步建议。

项目的评测规则、评分、诊断分类和报告生成使用 MoonBit；Node.js 适配层只负责在隔离的临时副本中启动本地命令。

## 解决什么问题

MoonBit 课程、训练营、社团和社区入门任务通常依赖人工检查：

- 学生只能看到一长串编译或测试输出；
- 教师需要重复运行每个仓库并手工汇总成绩；
- 教程示例缺少统一的完成标准；
- CI 能发现失败，却难以把失败转化为学习反馈；
- 不同教师对“通过”的评分口径不一致。

MoonGrade 将作业定义、执行、评分和反馈拆成明确阶段，使结果可复现、可比较、可集成到 CI。

## 三个使用场景

### 1. 教师批改课程作业

教师在一份 `assignment.json` 中定义编译检查、测试和自定义命令，并运行批量评测。MoonGrade 为每位学生生成 HTML、JSON 报告和班级汇总。

### 2. 学生自查

学生运行一条命令即可得到当前分数、每项检查的结果和针对性提示，不需要等待人工批改。

### 3. 社区维护教程示例

开源社区把教程示例接入 MoonGrade，将示例变成可自动验收的练习题，并用退出码阻止损坏的示例进入文档站点。

## 快速开始

需要 MoonBit 0.10.17 或更新版本，以及 Node.js 22 或更新版本。

```bash
git clone https://github.com/2227057182/moongrade.git
cd moongrade
moon update
moon check --deny-warn
moon test --deny-warn
```

评测一个学生项目：

```bash
moon run cmd/main -- grade \
  --assignment examples/assignment.json \
  --student examples/passing-student \
  --markdown passing-report.md \
  --json passing-report.json \
  --html passing-report.html \
  --fail-on-fail
```

批量批改：

```bash
moon run cmd/main -- batch \
  --assignment examples/assignment.json \
  --students examples \
  --reports examples/reports \
  --fail-on-fail
```

示例中 `passing-student` 得到 `100/100`，`failing-student` 得到 `65/100` 并触发失败退出码；`compile-error-student` 用于验证编译错误反馈。

## 作业定义

```json
{
  "name": "MoonBit Fundamentals",
  "pass_score": 70,
  "checks": [
    {
      "id": "compile",
      "title": "Project compiles",
      "kind": "check",
      "points": 30,
      "timeout_seconds": 60,
      "required": true
    },
    {
      "id": "tests",
      "title": "Public tests",
      "kind": "test",
      "points": 70,
      "timeout_seconds": 120,
      "required": true
    }
  ]
}
```

检查类型：

- `check`：执行 `moon check`；
- `test`：执行 `moon test`，根据通过测试比例计算得分；
- `command`：执行显式配置的本地命令。

每个检查支持独立分值、超时、是否必过和提示文本。详细格式见 [作业规范](docs/assignment-format.md)。

## 报告

- **Markdown**：适合代码仓库、课程平台和 PR。
- **JSON**：适合自动化收集和数据分析。
- **HTML**：自包含单文件，适合教师直接发给学生。
- **班级汇总**：批量记录每位学生的分数和通过状态。

## 设计原则

- **可复现**：不依赖在线评分服务或大模型推理。
- **可解释**：每个得分项都对应一个明确的命令和检查结果。
- **有反馈**：常见 MoonBit 编译错误会映射为可执行提示。
- **局部安全**：不经过 shell 拼接命令，所有子进程有输出上限与超时。
- **边界清晰**：评测在临时副本中进行，不修改学生原目录。

MoonGrade 面向本地可信作业，不是公网多租户恶意代码沙箱。运行不可信提交前应叠加容器或操作系统级隔离。

## 与现有学习工具的差异

Mooncakes 上的 `moonmentor` 侧重离线自适应学习路径；MoonGrade 侧重真实 MoonBit 项目的执行、评分和班级工作流。两者可以组合：MoonGrade 负责“运行和判定”，学习辅助工具负责“解释和练习推荐”。

## 验证

```bash
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon test . --target wasm --deny-warn
moon test . --target wasm-gc --deny-warn
./scripts/e2e.sh
```

Windows：

```powershell
./scripts/e2e.ps1
```

端到端脚本会实际评测一个通过项目、一个失败项目，并执行班级批量批改。

## 项目结构

```text
assignment.mbt       作业 JSON 解析与校验
scoring.mbt          部分得分、超时和错误提示
render.mbt           Markdown / JSON / HTML 报告
runtime/             薄 Node.js 本地进程适配层
cmd/main/            CLI 与批量评测
examples/            可运行作业、学生项目和报告
docs/                架构、格式、课堂流程与申报书
```

## 当前边界

- Node.js 适配层当前支持 JS 目标；
- 测试部分得分依赖 `moon test` 的标准汇总输出；
- 本地模式不提供容器级恶意代码隔离；
- 远程提交收集、账号系统和成绩数据库属于后续工作。

## 许可证

Apache-2.0。见 [LICENSE](LICENSE)。
