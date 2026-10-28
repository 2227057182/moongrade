# 作业定义格式

MoonGrade 使用 JSON 作业清单。顶层字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `name` | string | 是 | 作业名称 |
| `description` | string | 否 | 作业说明 |
| `pass_score` | positive integer | 是 | 通过所需分数 |
| `checks` | array | 是 | 至少一个检查项 |

## 检查项

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `id` | string | 是 | 唯一标识 |
| `title` | string | 否 | 展示名称，默认使用 `id` |
| `kind` | string | 否 | `check`、`test` 或 `command` |
| `points` | positive integer | 是 | 该项满分 |
| `timeout_seconds` | positive integer | 否 | 默认 120，最大 3600 |
| `required` | boolean | 否 | 默认 true；必过项失败会使整体失败 |
| `hint` | string | 否 | 无更具体诊断时展示的提示 |
| `command` | string array | `command` 时必填 | 直接执行，不经过 shell |

## 部分分

`test` 检查读取 MoonBit 测试汇总。例如：

```text
Total tests: 4, passed: 3, failed: 1.
```

若该检查满分 70，则得到 `52` 分，但检查本身仍标记为失败。

## 安全边界

命令数组直接传给 `spawnSync`，不进行 shell 拼接。每个进程有超时和 4 MB 输出上限。评测前会复制学生目录，避免测试修改原始提交。

该机制不是恶意代码沙箱。公网多租户环境必须再使用容器、只读文件系统、网络限制和资源配额。
