export type CacheTtl = '5m' | '1h'

declare module 'claude-code' {
  interface PluginState {
    'cache-timer': {
      lastAt: number | null
      ttl: CacheTtl
      tokens: number
      now: number
    }
  }
}
