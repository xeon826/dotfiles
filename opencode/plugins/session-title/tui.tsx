// TUI-only OpenCode plugin: shows the current session name in the
// prompt footer status row (after health indicators, before version).
// Reactive: updates live when the session is auto-titled or renamed.

import { Plugin } from "@opencode/plugin/tui"

export default Plugin.define({
  id: "dan.session-title",
  setup(context) {
    return context.ui.slot({
      append: "prompt.footer.status",
      render: ({ sessionID }) => {
        const title = sessionID ? context.data.session.get(sessionID)?.title : undefined
        if (!title) return null
        const fg = context.theme.text.muted ?? context.theme.text.secondary ?? context.theme.text.base
        return <text fg={fg}>{title}</text>
      },
    })
  },
})
