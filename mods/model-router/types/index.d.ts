export type RouterMode = 'auto' | 'haiku' | 'opus' | 'off'
export type RoutedModel = 'haiku' | 'opus'

export type Route = {
  model: RoutedModel
  reason: string
}

export type ActiveRoute = Route & { turnId: string }

export type LastUsed = { haiku: number | null; opus: number | null }

declare module 'claude-code' {
  interface PluginState {
    'model-router': {
      mode: RouterMode
      pending: Route | null
      active: ActiveRoute | null
      lastUsed: LastUsed
      lastAnswer: string
    }
  }
}
