# 课堂使用流程

## 准备作业

1. 创建学生起始仓库；
2. 编写公开测试和隐藏测试命令；
3. 创建 `assignment.json`；
4. 在通过和失败样例上运行 MoonGrade；
5. 将作业清单和起始仓库公开。

## 学生自查

```bash
moon run cmd/main -- grade \
  --assignment assignment.json \
  --student . \
  --html report.html \
  --fail-on-fail
```

学生先阅读失败检查项和输出摘要，再查看提示。教师可以在作业清单的 `hint` 中放置不会泄露隐藏测试的引导语。

## 教师批改

把每个学生仓库放在独立目录，只扫描包含 `moon.mod` 或 `moon.mod.json` 的项目：

```bash
moon run cmd/main -- batch \
  --assignment assignment.json \
  --students submissions \
  --reports reports \
  --fail-on-fail
```

生成的 `reports/summary.md` 记录学生、分数和通过状态。每个学生还会得到 JSON 和 HTML 详情。

## CI 门禁

将 `--fail-on-fail` 用于提交检查或发布任务。通过时退出码为 0，未通过时为 1，作业或运行配置错误时为 2。
