# KK Knock Introduction 开发日志

现行说明见 [README.md](../README.md)，下文是过程记录。

- 最后更新：2026-09-23
- 项目目录：`advertisement/`（GitHub 公开仓库 `KKnock-Boost/Introduction`）

## 首版介绍页（2026-09-23）

**页面与内容**
- 纯静态双语页面，EN / 中文可切换。不需要构建，没有 npm 依赖，也不请求任何第三方资源（字体、图片、脚本、统计都没有）。
- 语言默认跟随浏览器，切换后只把选择存在 `localStorage` 的 `kk-lang` 里。
- 首页结构依次是：首屏 → 不方便打字的场景 → KK Capture 1×1 → 说完之后的流程 → 功能 → 隐私 → 上手步骤 → 问答 → 结尾下载。另有“即将发布”页和 404 页。
- 内容主线是“手上正忙、不方便打字时用语音快速记录”。四个场景：在车上、买菜、做饭或带娃、会议间隙和通勤。
  - 每个场景写成“你说的话 → App 里的一行结果”。
  - 结果行里的日期由浏览器按访客当天实时计算，格式和 App 一致。
  - 开车场景限定为停车或安全停靠时使用，并附驾驶安全提示。
- KK Capture 1×1 用 App 里真实的三张状态图，就绪 → 录音中 → 处理中循环切换，并配有点击动画和同步高亮的说明。系统开启“减少动态效果”时停在就绪状态。
- 页面上的说法都按 App 的实际行为来写：
  - 一次录音只生成一条待办或一条想法，内容不足时不生成任何条目。
  - 录音不上传，只发送转写后的文字。
  - 服务器会把处理结果保留最多 14 天，用于重试去重。
  - 不写价格，也不承诺 iPhone 版。
- 视觉沿用 App 的 ADR-054 风格：暖象牙色底、森林绿和鼠尾草绿、Source Serif 4 标题（OFL-1.1，许可证在 `site/assets/fonts/OFL.txt`）。

**截图与素材**
- 截图来自手机 Debug 版的展示页 `ShowcaseActivity`：在内存数据库里放入虚构的示例数据，用真实界面渲染。
  - 不读写用户的数据库、小组件和日历，也不录音、不访问后端。
  - `scripts/capture-screens.sh` 通过 Wi-Fi adb 截取中英文各 8 屏，裁掉状态栏，存成 720px JPEG。每张都逐一检查过。
- 小组件预览图、KK Capture 三态图和 App 图标都来自 App 自身资源，只做了缩放。

**部署**
- 部署统一由 `../backend/compose.yaml` 的 `introduction` 服务负责：官方 `nginx:1.28-alpine` 镜像，只读挂载本仓库的 `site/`。
- nginx 配置放在 `../backend/deploy/introduction.conf.template`。本仓库不放 Dockerfile，只放内容。
- `/download` 跳转到部署环境变量 `INTRODUCTION_DOWNLOAD_URL`，只接受普通的 https 地址；为空或不合法时显示“即将发布”页。

**本地验证**（conda `appDev`，`scripts/preview.py`）
- 桌面 1280 和手机 390 宽度、中英文都检查过：控制台没有 CSP 报错，没有横向溢出，图片全部加载成功。
- `/download` 未设置地址时返回 200 的“即将发布”页；设置 https 地址时返回 302，并带 `no-store`。
- 404 页正常，`.` 开头的路径返回 404。
- 本机没有 Docker，镜像启动、nginx 配置和公网路由要在部署主机上验收。

**待完成**
- 正式 release 链接（由用户稍后提供）。
- 部署主机上的 `compose up`。
- Cloudflare 主机名路由。
