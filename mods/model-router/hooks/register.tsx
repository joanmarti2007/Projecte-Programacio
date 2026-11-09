import { atom, read, update } from 'claude-code'
import type { EngineInterface as Engine, Register } from 'claude-code'

import type { RoutedModel, Route, RouterMode } from '../types'

// Haiku's window is smaller than Opus's; leave room for the answer.
const HAIKU_MAX_CONTEXT = 150_000
// Past this size, moving off a warm Opus cache onto a cold Haiku one re-reads
// the whole conversation at full price, which can cost more than it saves.
const SWITCH_GUARD = 40_000
const CACHE_TTL_MS = 60 * 60_000
const ANSWER_CHARS = 1500

const mode = atom({ plugin: 'model-router', key: 'mode' } as const, 'auto')
const pending = atom({ plugin: 'model-router', key: 'pending' } as const, null)
const active = atom({ plugin: 'model-router', key: 'active' } as const, null)
const lastUsed = atom({ plugin: 'model-router', key: 'lastUsed' } as const, {
  haiku: null,
  opus: null,
})
const lastAnswer = atom({ plugin: 'model-router', key: 'lastAnswer' } as const, '')

const NAMES: Record<RoutedModel, string> = { haiku: 'Haiku', opus: 'Opus' }
const ICONS: Record<RoutedModel, string> = { haiku: '🐇', opus: '🧠' }

function formatTokens(n: number): string {
  return n >= 1000 ? `${Math.round(n / 1000)}k` : String(n)
}

async function isWarm($: Engine, model: RoutedModel): Promise<boolean> {
  const at = (await read($, lastUsed))[model]
  return at !== null && (await $.clock.now()) - at < CACHE_TTL_MS
}

async function classify($: Engine, text: string): Promise<'simple' | 'complex' | undefined> {
  const previous = (await read($, lastAnswer)).slice(-ANSWER_CHARS)
  const sample = previous
    ? `Última respuesta del asistente (final):\n${previous}\n\nNueva petición del usuario:\n${text}`
    : `Petición del usuario:\n${text}`
  try {
    const label = await $.model.classify(sample, ['simple', 'complex'])
    return label === 'simple' || label === 'complex' ? label : undefined
  } catch {
    return undefined
  }
}

async function decide($: Engine, text: string): Promise<Route> {
  const current = await read($, mode)
  if (current === 'haiku' || current === 'opus') {
    return { model: current, reason: 'forzado con /router' }
  }

  const context = (await $.session.usage()).context.tokens ?? 0
  if (context > HAIKU_MAX_CONTEXT) {
    return { model: 'opus', reason: `contexto grande (~${formatTokens(context)} tokens)` }
  }

  const label = await classify($, text)
  if (label === undefined) return { model: 'opus', reason: 'no se pudo clasificar' }
  if (label === 'complex') return { model: 'opus', reason: 'tarea compleja' }

  if (context > SWITCH_GUARD && (await isWarm($, 'opus')) && !(await isWarm($, 'haiku'))) {
    return {
      model: 'opus',
      reason: `tarea sencilla, pero cambiar a Haiku releería ~${formatTokens(context)} tokens sin caché`,
    }
  }
  return { model: 'haiku', reason: 'tarea sencilla' }
}

async function routePrompt($: Engine, text: string) {
  const route = (await read($, mode)) === 'off' ? null : await decide($, text)
  await update($, pending, () => route)
}

async function showStatus($: Engine) {
  const current = await read($, mode)
  const route = await read($, active)
  if (current === 'off') {
    $.ui.status(undefined)
    return
  }
  const label = route ? `${ICONS[route.model]} ${NAMES[route.model]}` : 'esperando'
  $.ui.status(current === 'auto' ? `router: ${label}` : `router: ${label} (forzado)`)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'router',
      description: 'Reparto entre Haiku y Opus: /router, /router auto|haiku|opus|off',
      argumentHint: '[auto|haiku|opus|off]',
    })
    await showStatus($)

    return next(e)
  })

  on('prompt.submit', async ($, e, next) => {
    // Slash commands, hidden prompts and messages typed into a running turn
    // keep whatever the turn already uses.
    if (e.command !== undefined || e.isMeta || e.turnId !== undefined) return next(e)

    // A failure here must never hold the prompt back: it just goes unrouted.
    await routePrompt($, e.text).catch(() => undefined)

    return next(e)
  })

  on('turn.start', async ($, e, next) => {
    if (e.agentId === undefined) {
      const route = await read($, pending)
      await update($, pending, () => null)
      await update($, active, () => (route ? { ...route, turnId: e.turnId } : null))
      await showStatus($)
    }

    return next(e)
  })

  on('turn.step', async function* ($, e, next) {
    const route = await read($, active)
    // Subagents keep the model they were started with.
    if (e.agentId !== undefined || route === null || route.turnId !== e.turnId) {
      return yield* next(e)
    }

    const at = await $.clock.now()
    await update($, lastUsed, used => ({ ...used, [route.model]: at }))

    return yield* next({ ...e, model: route.model })
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId === undefined) {
      await update($, lastAnswer, () => e.answer.slice(-ANSWER_CHARS))
    }

    return result
  })

  on('command.run', { command: 'router' }, async ($, e) => {
    const arg = e.args.trim()
    if (arg === 'auto' || arg === 'haiku' || arg === 'opus' || arg === 'off') {
      const chosen: RouterMode = arg
      await update($, mode, () => chosen)
      await showStatus($)
    } else if (arg !== '') {
      return { text: 'Uso: /router, /router auto, /router haiku, /router opus o /router off' }
    }

    const current = await read($, mode)
    const route = await read($, active)
    const modes: Record<RouterMode, string> = {
      auto: 'automático: Haiku para tareas sencillas, Opus para las complejas',
      haiku: 'todo con Haiku',
      opus: 'todo con Opus',
      off: 'apagado: se usa el modelo de la sesión',
    }
    const last = route
      ? ` Último mensaje: ${NAMES[route.model]} (${route.reason}).`
      : ''

    return { text: `Router ${modes[current]}.${last}` }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const route = await read($, active)
    const current = await read($, mode)
    if (e.props.hasSurvey || route === null || current === 'off') return next(e)

    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box>
        <Text dimColor>
          {ICONS[route.model]} Último mensaje con {NAMES[route.model]}: {route.reason}
        </Text>
      </Box>
    )
  })
}
