# GitHub Actions 自动部署到阿里云 ECS

通过 GitHub Actions，在每次 push 到 `master` 分支时，自动将站点部署到阿里云 ECS 的 `/var/www/ai-toolkit-map` 目录。

- 域名：`aihot.gouxinjie.com`
- 协议：HTTP（80 端口）
- ECS 上 Nginx 监听 80 端口，与其他项目通过 `server_name` 共存，互不影响

---

## 一、项目文件说明

本方案包含两个文件：

| 文件 | 作用 |
|------|------|
| `.github/workflows/deploy.yml` | GitHub Actions 工作流：SSH 同步代码到 ECS |
| `deploy/server_aihot.conf` | Nginx 站点配置（复制到 ECS 使用） |

---

## 二、在 GitHub 仓库配置 Secrets

进入仓库 → `Settings` → `Secrets and variables` → `Actions` → `New repository secret`，添加以下 4 个密钥：

| Secret 名称 | 说明 | 示例 |
|------------|------|------|
| `ECS_SSH_KEY` | ECS 的 SSH 私钥内容（完整的多行文本） | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `ECS_HOST` | ECS 公网 IP | `47.xxx.xxx.xxx` |
| `ECS_USER` | SSH 登录用户（建议 `root` 或用普通用户） | `root` |
| `ECS_PORT` | SSH 端口 | `22` |

> **注意**：`ECS_SSH_KEY` 是私钥的**完整内容**，要原样粘贴（含首尾的 `BEGIN/END` 标记行）。

### 私钥换行符问题（error in libcrypto）

部署失败的常见原因是私钥在 Secrets 里被破坏了。若遇到 `error in libcrypto` 或 `Permission denied`，按顺序排查：

1. **在编辑器里新建文件**（不要直接复制进 Secrets 输入框），把私钥内容粘贴进去，保存后用文本方式确认换行符是 `LF`（Linux 换行），不是 `CRLF`（Windows 换行）。
2. **删除并重新创建** `ECS_SSH_KEY` Secret，重新完整粘贴一遍（含首尾标记行）。
3. 确认该私钥**确实能免密登录** ECS（本机 `ssh -i <key> user@host` 无需密码）。
4. 工作流已使用 `webfactory/ssh-agent` 加载私钥，它对多行私钥的换行符处理更健壮。

---

## 三、ECS 端一次性准备

### 1. 创建部署目录

```bash
# 使用密钥对应的用户登录后
sudo mkdir -p /var/www/ai-toolkit-map
# 给当前 SSH 用户授权（将 USER 换成你实际的登录用户）
sudo chown -R USER:USER /var/www/ai-toolkit-map
```

### 2. 配置 Nginx

把 `deploy/server_aihot.conf` 复制到 ECS 上：

```bash
sudo cp server_aihot.conf /etc/nginx/conf.d/
# 检查配置语法
sudo nginx -t
# 重新加载
sudo nginx -s reload
```

> 阿里云 ECS 的 Nginx 通常默认 include `/etc/nginx/conf.d/*.conf`。
> 如果你的 Nginx 主配置没有 include 该目录，请在 `/etc/nginx/nginx.conf` 的 `http` 块内补充：
> ```nginx
> include /etc/nginx/conf.d/*.conf;
> ```

### 3. 域名解析

在阿里云 DNS 控制台，为 `gouxinjie.com` 添加一条 **A 记录**：

| 记录类型 | 主机记录 | 记录值 |
|---------|---------|--------|
| A | `aihot` | 你的 ECS 公网 IP |

### 4. 安全组放行 80 端口

在阿里云 ECS 控制台 → 实例 → 安全组 → 入方向规则，放行：

| 端口 | 来源 |
|------|------|
| TCP 80 | 0.0.0.0/0 |

---

## 四、SSH 密钥配置说明（重要）

Workflow 使用 SSH 私钥免密登录部署。推荐做法：

1. **在 ECS 上生成**密钥对（或用已有密钥）：

```bash
ssh-keygen -t ed25519 -C "github-actions"
# 把公钥追加到授权列表
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

2. 将**私钥** `~/.ssh/id_ed25519` 的内容填到 GitHub 的 `ECS_SSH_KEY` 中。

> 若不想用 root，可在 ECS 上创建专用部署用户并授权到 `/var/www/ai-toolkit-map`。

---

## 五、触发部署

- **自动触发**：任何 push 到 `master` 分支都会自动部署。
- **手动触发**：在 Actions 页面选中该 workflow → `Run workflow`。

部署成功后，访问 `http://aihot.gouxinjie.com` 即可看到站点。

---

## 六、检查部署结果

在 GitHub `Actions` 标签页查看运行日志，确认 `Deploy to Aliyun ECS` 步骤显示成功（绿色 ✓）。

也可在 ECS 上验证：

```bash
ls -la /var/www/ai-toolkit-map
curl -I http://aihot.gouxinjie.com
```

---

## 七、常见问题

| 问题 | 排查方向 |
|------|---------|
| 部署失败：`Host key verification failed` | 在 SSH 配置里添加 `StrictHostKeyChecking=no`（见下方说明） |
| 域名打不开 | 检查 DNS 解析、安全组 80 端口、Nginx 配置是否 reload |
| 其他项目不受影响 | 已按 `server_name` 隔离，多个域名各自独立 server 块即可 |

若遇到 host key 验证问题，可将部署步骤中的 `ARGS` 补充参数：

```yaml
ARGS: "-avz --delete -o StrictHostKeyChecking=no"
```
