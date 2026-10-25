/**
 * dsh-tiaforge —— 把 TIA Forge 的四个技能与四个 MCP 端点接进 DeepSeek Harness。
 *
 * 技能：读取包内 `skills/<name>/SKILL.md`，在插件 apply 阶段注册进 ctx.skills。
 *       走"嵌入式插件数据"这条路，不依赖用户把文件拷到 .dsh/skills。
 * MCP： 由 cordis.patch.yml 里的 @deepseek-ai/dsh-mcp-client 行负责，本文件不碰。
 */
import { readFileSync, readdirSync, existsSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

export const name = 'tiaforge-skills'

const SKILLS_DIR = join(dirname(fileURLToPath(import.meta.url)), 'skills')

/** 极简 frontmatter 解析：只取顶层 `key: value`，够用且不引入依赖。 */
function parseFrontmatter(raw) {
  const m = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/.exec(raw)
  if (!m) return { data: {}, body: raw }
  const data = {}
  for (const line of m[1].split(/\r?\n/)) {
    const kv = /^([A-Za-z0-9_-]+):\s*(.*)$/.exec(line)
    if (!kv) continue
    let value = kv[2].trim()
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1)
    }
    data[kv[1]] = value
  }
  return { data, body: m[2] }
}

export function apply(ctx) {
  if (!existsSync(SKILLS_DIR)) {
    ctx.logger?.warn?.(`[dsh-tiaforge] 找不到技能目录: ${SKILLS_DIR}`)
    return
  }

  for (const entry of readdirSync(SKILLS_DIR, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue
    const file = join(SKILLS_DIR, entry.name, 'SKILL.md')
    if (!existsSync(file)) continue

    try {
      const raw = readFileSync(file, 'utf8')
      const { data, body } = parseFrontmatter(raw)
      const skillName = data.name || entry.name
      const description = data.description || data.summary || ''

      if (!description) {
        ctx.logger?.warn?.(`[dsh-tiaforge] ${entry.name}: 缺少 description，跳过`)
        continue
      }

      const dispose = ctx.skills.register({
        name: skillName,
        description,
        whenToUse: data.whenToUse,
        path: file,
        content: body,
        metadata: { publisher: '汇智网 (hubwiz.com)', homepage: data.homepage },
      })

      // 注册在 apply 期间完成；dispose 交给 Cordis 的 effect 生命周期管理
      ctx.effect?.(() => dispose)
    } catch (error) {
      ctx.logger?.warn?.(`[dsh-tiaforge] 载入 ${entry.name} 失败: ${error?.message ?? error}`)
    }
  }
}
