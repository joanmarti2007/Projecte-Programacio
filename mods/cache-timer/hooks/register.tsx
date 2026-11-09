import { atom, read, update } from 'claude-code'
import type { EngineInterface as Engine, Register, Timer } from 'claude-code'

import type { CacheTtl } from '../types'

const TTL_MS: Record<CacheTtl, number> = { '5m': 5 * 60_000, '1h': 60 * 60_000 }
// How long before expiry the "se enfría pronto" warning fires.
const WARN_MS: Record<CacheTtl, number> = { '5m': 60_000, '1h': 5 * 60_000 }
const TICK_MS = 30_000

const lastAt = atom({ plugin: 'cache-timer', key: 'lastAt' } as const, null)
const ttl = atom({ plugin: 'cache-timer', key: 'ttl' } as const, '1h')
const tokens = atom({ plugin: 'cache-timer', key: 'tokens' } as const, 0)
// Written every tick so the band and status line redraw.
const now = atom({ plugin: 'cache-timer', key: 'now' } as const, 0)

// Module variables start over on a reload; session.start reschedules them.
let warnTimer: Timer | undefined
let coldTimer: Timer | undefined
let tick: Timer | undefined

type CacheState =
  | { kind: 'none' }
  | { kind: 'warm' | 'cooling'; leftMs: number; tokens: number }
  | { kind: 'cold'; agoMs: number; tokens: number }

function formatTokens(n: number): string {
  return n >= 1000 ? `${Math.round(n / 1000)}k` : String(n)
}

function formatMinutes(ms: number): string {
  const min = Math.max(0, Math.round(ms / 60_000))
  if (min < 1) return 'menos de 1 min'
  if (min < 60) return `${min} min`
  const h = Math.floor(min / 60)
  const m = min % 60
  return m === 0 ? `${h} h` : `${h} h ${m} min`
}

function statusText(s: CacheState): string | undefined {
  switch (s.kind) {
    case 'none':
      return undefined
    case 'warm':
      return `🔥 caché ${formatMinutes(s.leftMs)}`
    case 'cooling':
      return `⏳ caché se enfría en ${formatMinutes(s.leftMs)}`
    case 'cold':
      return '🧊 caché fría'
  }
}

async function cacheState($: Engine): Promise<CacheState> {
  const at = await read($, lastAt)
  if (at === null) return { kind: 'none' }
  const mode = await read($, ttl)
  const used = await read($, tokens)
  const left = at + TTL_MS[mode] - (await $.clock.now())
  if (left <= 0) return { kind: 'cold', agoMs: -left, tokens: used }
  return { kind: left <= WARN_MS[mode] ? 'cooling' : 'warm', leftMs: left, tokens: used }
}

async function refresh($: Engine) {
  const t = await $.clock.now()
  await update($, now, () => t)
  $.ui.status(statusText(await cacheState($)))
}

async function warnCooling($: Engine, mode: CacheTtl) {
  const used = await read($, tokens)
  $.ui.toast(
    `⏳ La caché se enfría en ${formatMinutes(WARN_MS[mode])}. Si vas a seguir, escribe ahora; si no, el próximo mensaje releerá ~${formatTokens(used)} tokens.`,
    { timeoutMs: 15_000 },
  )
  await refresh($)
}

async function warnCold($: Engine) {
  const used = await read($, tokens)
  $.ui.toast(
    `🧊 La caché se ha enfriado. El próximo mensaje releerá ~${formatTokens(used)} tokens a precio completo. Para algo nuevo, plantéate /clear o una sesión nueva.`,
    { timeoutMs: 20_000 },
  )
  await refresh($)
}

async function schedule($: Engine) {
  warnTimer?.cancel()
  coldTimer?.cancel()
  const at = await read($, lastAt)
  if (at === null) return
  const mode = await read($, ttl)
  const left = at + TTL_MS[mode] - (await $.clock.now())
  if (left <= 0) return

  const warnIn = left - WARN_MS[mode]
  if (warnIn > 0) {
    warnTimer = $.clock.after(warnIn, () => void warnCooling($, mode))
  }
  coldTimer = $.clock.after(left, () => void warnCold($))
}

async function describe($: Engine): Promise<string> {
  const mode = await read($, ttl)
  const s = await cacheState($)
  const head = `Duración de la caché: ${mode === '1h' ? '1 hora' : '5 minutos'}.`
  switch (s.kind) {
    case 'none':
      return `${head} Todavía no hay ninguna respuesta en esta sesión.`
    case 'cold':
      return `${head} 🧊 Fría desde hace ${formatMinutes(s.agoMs)}: el próximo mensaje relee ~${formatTokens(s.tokens)} tokens a precio completo.`
    default:
      return `${head} 🔥 Caliente: se enfría en ${formatMinutes(s.leftMs)} (~${formatTokens(s.tokens)} tokens en caché).`
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'cache',
      description: 'Estado de la caché de la conversación; /cache 5m o /cache 1h cambia la duración',
      argumentHint: '[5m|1h]',
    })
    tick?.cancel()
    tick = $.clock.every(TICK_MS, () => void refresh($))
    await schedule($)
    await refresh($)

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    // Subagents run in their own cache; only the main conversation counts.
    if (e.agentId !== undefined) return result

    const usage = await $.session.usage()
    await update($, tokens, () => usage.context.tokens ?? 0)
    const at = await $.clock.now()
    await update($, lastAt, () => at)
    await schedule($)
    await refresh($)

    return result
  })

  on('command.run', { command: 'cache' }, async ($, e) => {
    const arg = e.args.trim()
    if (arg === '5m' || arg === '1h') {
      await update($, ttl, () => arg)
      await schedule($)
      await refresh($)
    } else if (arg !== '') {
      return { text: 'Uso: /cache, /cache 5m o /cache 1h' }
    }

    return { text: await describe($) }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    await read($, now)
    const s = await cacheState($)
    if (e.props.hasSurvey || e.props.isWorking || s.kind === 'none') return next(e)

    const { Box, Text } = $.ui.resolve(e)
    const size = `~${formatTokens(s.tokens)} tokens`

    if (s.kind === 'cold') {
      return (
        <Box>
          <Text color="cyan">
            🧊 Caché fría desde hace {formatMinutes(s.agoMs)}: tu próximo mensaje relee {size} a precio completo
          </Text>
        </Box>
      )
    }
    if (s.kind === 'cooling') {
      return (
        <Box>
          <Text color="yellow">
            ⏳ La caché se enfría en {formatMinutes(s.leftMs)} ({size} en caché)
          </Text>
        </Box>
      )
    }

    return (
      <Box>
        <Text dimColor>
          🔥 Caché caliente · se enfría en {formatMinutes(s.leftMs)} ({size})
        </Text>
      </Box>
    )
  })
}
