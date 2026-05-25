---
name: lark
version: 1.0.0
description: "Lark/Feishu CLI skills: lark-cli operations for docs, markdown, sheets, base, calendar, im, mail, task, okr, drive, wiki, slides, whiteboard, apps, approval, attendance, contact, vc, minutes, event. When user needs to operate Lark/Feishu resources via lark-cli, send messages, manage documents, spreadsheets, calendars, tasks, OKRs, deploy web pages, or any Feishu/Lark workspace operations."
metadata:
  requires:
    bins: ["lark-cli"]
---

# Lark CLI Skills

**CRITICAL** -- Before any lark-cli operation, MUST first read [`lark-shared/SKILL.md`](lark-shared/SKILL.md) for authentication, identity, permissions, and security rules.

This skill is a router for all Lark/Feishu CLI operations. Based on user intent, read the corresponding sub-skill SKILL.md before executing.

## Sub-skill Index

| Sub-skill | Directory | Use When |
|-----------|-----------|----------|
| Shared Config & Auth | `lark-shared/` | First-time setup, `config init`, `auth login`, permission errors, identity switching |
| Documents | `lark-doc/` | Create/edit/fetch/search Feishu docs, insert media, whiteboard in docs |
| Markdown | `lark-markdown/` | View/create/upload/edit/diff Markdown files in Feishu |
| Spreadsheets | `lark-sheets/` | Read/write cells, formulas, styles, filter views, merge/unmerge, dropdowns |
| Multidimensional Tables | `lark-base/` | Bitable tables, fields, records, views, forms, dashboards, workflows, roles |
| Calendar | `lark-calendar/` | Events, meetings, room booking, free/busy, RSVP, schedule suggestions |
| Instant Messaging | `lark-im/` | Send/reply messages, search chats, manage groups, download files, reactions |
| Email | `lark-mail/` | Send/reply/forward email, drafts, triage, signatures, watch mailbox |
| Tasks | `lark-task/` | Create/update/search tasks, task lists, reminders, subtasks, followers |
| OKR | `lark-okr/` | View/edit OKR cycles, objectives, key results, alignments, metrics, progress |
| Drive | `lark-drive/` | Upload/download files, folders, shortcuts, comments, reactions, export/import |
| Wiki | `lark-wiki/` | Wiki spaces, create/move wiki nodes |
| Slides | `lark-slides/` | Create/edit presentations, upload media, XML-based slide manipulation |
| Web Apps (Miaoda) | `lark-apps/` | Deploy local HTML/static sites to Feishu Miaoda, get shareable URLs, manage app access scope |
| Whiteboard | `lark-whiteboard/` | Query/export/update whiteboards; create diagrams (flowcharts, architecture, org charts, timelines) via PlantUML/Mermaid/native format |
| Approval | `lark-approval/` | Query and manage approval instances and definitions |
| Attendance | `lark-attendance/` | Attendance records, shifts, check-in/out |
| Contact | `lark-contact/` | Search/get user info, department lookup |
| Video Conference | `lark-vc/` | Meeting recordings, notes, search meetings |
| VC Agent (live) | `lark-vc-agent/` | Bot joins/leaves an ongoing meeting on your behalf; read live in-meeting events (joins, speech, chat, screen share) |
| Minutes | `lark-minutes/` | Search/download meeting minutes |
| Event Subscription | `lark-event/` | Subscribe to Lark event callbacks |
| OpenAPI Explorer | `lark-openapi-explorer/` | Discover and explore Lark OpenAPI endpoints |
| Skill Maker | `lark-skill-maker/` | Create new lark-cli skills |
| Workflow: Meeting Summary | `lark-workflow-meeting-summary/` | Automated meeting summary workflow |
| Workflow: Standup Report | `lark-workflow-standup-report/` | Automated standup report workflow |

## Routing Rules

1. Always read `lark-shared/SKILL.md` first for auth context
2. Identify the target sub-skill from the index above
3. Read the sub-skill's `SKILL.md` for detailed instructions and shortcuts
4. Sub-skill references/ directories contain per-command details -- read as needed
5. For whiteboard content in documents, coordinate between `lark-doc` and `lark-whiteboard` (the former `lark-whiteboard-cli` is now merged into `lark-whiteboard`)
