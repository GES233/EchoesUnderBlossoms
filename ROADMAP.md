# 路线规划

## 基本的 UCG 社交功能

### 用户

#### 用户的注册、登录与 `%AuditLog{}`

再次基础上，通过修改 `phx mix.gen.auth` 自动生成的代码来处理（也可以魔改此前废弃项目的相关代码，其已经实现了 AuditLog 基于 bytepack）。

- [x] 将 `mix phx.gen.auth` 的代码的注释/文档翻译成中文
  - [x] `MemberAuth` 的文档与注释
  - [x] `HanaShirabe.Accounts.MemberToken`
  - [x] `HanaShirabe.Accounts`
  - [x] `HanaShirabeWeb.ConnCase`
  -  一堆测试代码
    - [x] `HanaShirabe.AccountsTest`
    - [x] `HanaShirabeWeb.MemberSessionControllerTest`
    - [x] `HanaShirabeWeb.MemberLive.ConfirmationTest`
    - [x] `HanaShirabeWeb.MemberLive.LoginTest`
    - [x] `HanaShirabeWeb.MemberLive.RegistrationTest`
    - [x] `HanaShirabeWeb.MemberLive.SensitiveSettingsTest`
- [x] 创建有关 AuditLog 相关的 mount_helpers ，使之可以通过 `on_mount {HanaShirabeWeb.AuditLogInjector, :mount_audit_log}` 被挂载
  - [x] 测试
  - [ ] 编写测试代码（包括 Plug 以及 LiveView）
- [x] 将注册的函数与 `%AuditLog{}` 合并
- [x] 修改代码使测试跑通
  - 是 Gettext 会翻译部分错误信息，这和测试代码的断言不一致（修改完成）
- [x] 添加 `AuditLog.Context` 将上下文归一并且执行验证函数
  - [x] 确定 `scope` 是 `t:atom()` 还是 `t:list(atom())`
- [x] 实现登录、验证、邮件修改的 AuditLog 操作
- [x] 实现网页国际化的功能（主要是一堆 LiveView 里乱七八糟的）
- [ ] 优化「注册」与「修改信息」的流程
  - [x] 把 `member_live` 里的那些东西搞成多语言
  - 我倒是觉得先激活邮件再填写密码的方式很好
  - [x] 仅有敏感操作（例如修改密码邮件）需要 sudo
    - （形如 GitHub ，将敏感操作划分为 Danger Zone）

#### 用户的属性

- `nickname`
  - 用户的昵称
- `username`
  - 【需要讨论】类似于 X 的两重用户名，但一旦选择 UID 方案，此键放弃
- `status`
  - 账号的状态（包括未激活、正常、被封禁、被清退、已注销、主动冻结留档六种状态）
  - 状态转移的主体包括网站、用户本人以及对用户有管理权限的管理员
- `join_at`（`confirmed_at`）
  - 加入的时间（按照被激活的时间算起）
- `avatar_link`
  - 【需要确定头像方案后落实】
- `prefer_locale`
  - 语言相关，决定了界面的语言选择
  - 之前向根据请求的时区以及系统语言来决策，但那样好麻烦，还有一种方案是本地 Cookie
- `intro`
  - 自我介绍

- [ ] 实现个人主页
  - [ ] 添加 `~p/me/` 以及 `~p/m/:id` 路由
  - [ ] 添加昵称、用户名、个人简介
  - [ ] 个人主页包括基本信息
- [ ] 实现头像
  - [ ] 自动生成
  - [ ] 站内保存
  - [ ] 外部链接
- [ ] 个人信息的修改
  - [x] 页面设计
  - [ ] 更新

### 跑通现有的测试用例

尽力提高 coverage 。

### 多语言支持

计划通过客户端 Cookie + 浏览器请求头的 Accept-Language 实现。

当前已经实现对应的 Plug 。

其预计包含（优先级依次向后）：

- 请求的 `locale` 参数
- Cookie 的信息（如有）
- 用户的偏好（可能要修改数据表并设计页面）
- 浏览器请求头的 Accept-Language
- 应用默认

- [x] 页面多语言
- [x] 注册页面
- [ ] 多时区实现
  - [ ] Elixir TimeZone Database
  - [ ] 数据表
  - [ ] 前端

### 页面的设计与实现

### 内容的创建、处理以及导出

以用户的 Post 以及 Comment 为例。

#### 处理

渲染为 HTML 。

#### 导出

转化为 Markdown （链接）。

#### 导入

转化为 Markdown （内部）。

### 草稿箱的设计与实现

后端部分：

- 创建数据表（数据表是 `context/draft`）
- 增删改查
- 需要设计到所有内容相关业务的生命周期中：未被发送就保存、发送成功即删除

前端部分：

- 将 Markdown 文本注入 `placeholder`

### 消息机制、`@` 、邀请机制与社交关系

### 多设备管理

## 核心业务的梳理、设计与实现

### 媒体资源

#### 媒体资源的定义、分类与设计

#### 站内媒体资源的生命周期

简单来讲就是回答「哪里来」、「**怎么证明**」以及「关联者有何情况」的问题。

### 作者/厂商

TBD

### 提案的生命周期的设计与实现

这是最重要的。
