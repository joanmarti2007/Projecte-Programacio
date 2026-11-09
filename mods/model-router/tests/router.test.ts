import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

type Stubs = { label: string; tokens: number; models: string[]; clock: { now: number } }

function engine(on: On, s: Stubs) {
  on('clock.now', () => ({ value: s.clock.now }))
  on('command.register', () => ({ value: { command: 'router' } }))
  on('model.classify', () => ({ value: s.label }))
  on('session.usage', () => ({
    value: { startedAt: 0, context: { tokens: s.tokens, window: 1_000_000 }, rateLimits: [] },
  }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('prompt.submit', (_, e) => ({ text: e.text }))
  on('turn.start', (_, e) => ({ turnId: e.turnId }))
  on('turn.complete', () => ({ text: '' }))
  on('turn.step', async function* (_, e) {
    s.models.push(e.model)
    return { turnId: e.turnId, index: e.index, answer: '', toolUses: [] }
  })
}

async function ask($: Parameters<Parameters<typeof test>[1]>[0], text: string, turnId: string) {
  await $.prompt.submit({ text, wait: false })
  await $.turn.start({ text, turnId })
  for await (const _ of $.turn.step({ turnId, index: 0, model: 'claude-opus-5-5', messageCount: 1 })) {
    // drain
  }
  await $.turn.complete({ answer: 'ok', durationMs: 1, isAborted: false, turnId, reason: 'answer' })
}

test('una tarea sencilla va a Haiku y una compleja a Opus', async ($, on) => {
  const s: Stubs = { label: 'simple', tokens: 5_000, models: [], clock: { now: 0 } }
  engine(on, s)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  await ask($, '¿Qué hora es en Tokio?', 't1')
  s.label = 'complex'
  await ask($, 'Diseña la arquitectura de una app con backend y tests', 't2')

  expect(s.models).toEqual(['haiku', 'opus'])
})

test('con mucho contexto y la caché de Opus caliente no cambia a Haiku', async ($, on) => {
  const s: Stubs = { label: 'complex', tokens: 100_000, models: [], clock: { now: 0 } }
  engine(on, s)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  await ask($, 'Refactoriza todo el proyecto', 't1')
  s.label = 'simple'
  s.clock.now += 60_000
  await ask($, 'gracias', 't2')

  expect(s.models).toEqual(['opus', 'opus'])
  expect((await $.command.run({ command: 'router', args: '' })).text).toContain('sin caché')
})

test('más contexto del que cabe en Haiku va siempre a Opus', async ($, on) => {
  const s: Stubs = { label: 'simple', tokens: 300_000, models: [], clock: { now: 0 } }
  engine(on, s)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  await ask($, 'ok', 't1')
  expect(s.models).toEqual(['opus'])
})

test('/router haiku fuerza Haiku y /router off deja el modelo de la sesión', async ($, on) => {
  const s: Stubs = { label: 'complex', tokens: 5_000, models: [], clock: { now: 0 } }
  engine(on, s)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  await $.command.run({ command: 'router', args: 'haiku' })
  await ask($, 'Diseña un compilador', 't1')
  await $.command.run({ command: 'router', args: 'off' })
  await ask($, 'Diseña otro compilador', 't2')

  expect(s.models).toEqual(['haiku', 'claude-opus-5-5'])
})
