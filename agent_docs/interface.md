# Interface roles

Use semantic system colors, not fixed light/dark hex values or per-icon opacity adjustments.

- Primary: list titles and unfinished task text.
- Secondary: neutral action icons, completion circles, input affordances, and completed task text.
- Tertiary: drag-handle detail and disabled action icons.
- Blue, orange, red: low, medium, and high priority respectively. Priority is also named in the menu and accessibility label.
- System accent: active drop-position feedback, not completed tasks.

Neutral action icons share `TaskControlIcon` in `Sources/TodoMenuBar/task-control-icon.swift:3`. Buttons use plain styling; menus retain native behavior but draw their icon as a noninteractive overlay. This prevents AppKit menu and button label treatments from producing different shades.

Keep existing control frames and column alignment. Destructive task actions stay neutral until invoked; do not make every trash icon red. Preserve native keyboard focus, accessible action labels, and disabled states.
