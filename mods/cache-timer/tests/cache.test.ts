import { expect, test } from 'claude-code/testing'

const MIN = 60_000

test('/cache cuenta la hora de caché desde la última respuesta', async ($, on) => {
  let clock = 1_000_000
  on('clock.now', () => ({ value: clock }))
  on('clock.after', () => ({ value: undefined }))
  on('clock.every', () => ({ value: undefined }))
  on('command.register', () => ({ value: { command: 'cache' } }))
  on('session.usage', () => ({
    value: { startedAt: 0, context: { tokens: 120_000, window: 200_000 }, rateLimits: [] },
  }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('turn.complete', () => ({ text: '' }))

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  expect((await $.command.run({ command: 'cache', args: '' })).text).toContain('Todavía no hay')

  await $.turn.complete({ answer: '', durationMs: 1, isAborted: false, turnId: 't1', reason: 'answer' })

  clock += 20 * MIN
  expect((await $.command.run({ command: 'cache', args: '' })).text).toContain('se enfría en 40 min')
  expect((await $.command.run({ command: 'cache', args: '' })).text).toContain('~120k tokens')

  clock += 50 * MIN
  expect((await $.command.run({ command: 'cache', args: '' })).text).toContain('Fría desde hace 10 min')

  // Con 5 minutos de duración, 70 min después ya hace 65 min que está fría.
  expect((await $.command.run({ command: 'cache', args: '5m' })).text).toContain('Fría desde hace 1 h 5 min')
})

test('los subagentes no reinician el contador', async ($, on) => {
  let clock = 0
  on('clock.now', () => ({ value: clock }))
  on('clock.after', () => ({ value: undefined }))
  on('clock.every', () => ({ value: undefined }))
  on('command.register', () => ({ value: { command: 'cache' } }))
  on('session.usage', () => ({
    value: { startedAt: 0, context: { tokens: 5_000, window: 200_000 }, rateLimits: [] },
  }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('turn.complete', () => ({ text: '' }))

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await $.turn.complete({ answer: '', durationMs: 1, isAborted: false, turnId: 'a', agentId: 'sub', reason: 'answer' })
  expect((await $.command.run({ command: 'cache', args: '' })).text).toContain('Todavía no hay')
})
