# discourse-workflow

A workflow tool for Discourse!

Discuss the plugin here: https://meta.discourse.org/t/discourse-workflow/347110?u=merefield

## Introduction

A plugin which provides a secure workflow framework for Topics which are passed along a customizable set of steps until the workflow is complete. Some branching and looping is supported.

If you are new to the terminology, see:

- Workflow: https://en.wikipedia.org/wiki/Workflow
- Business process: https://en.wikipedia.org/wiki/Business_process

## Features

- Workflow definitions made from steps mapped to Categories (or Sub-categories)
- Workflow instances represented as Topics that transition across Categories
- Transition actions presented as buttons per step option
- Permission model aligned to native Discourse category permissions
- Workflow discovery list (`/workflow`) with quick filters
- Workflow view selector in discovery (`List`, `Kanban`, `Chart`) when applicable
- Kanban view for compatible single-workflow lists
- Drag/drop transitions in Kanban with legal/illegal drop-zone highlighting
- Keyboard Kanban transitions on focused cards (`ArrowLeft` / `ArrowRight`) when legal
- Workflow-level Kanban tags toggle (`show_kanban_tags`, default `true`)
- Workflow burn down chart view (`/workflow/charts` and chart mode in `/workflow`) for single-workflow context
- Chart period selector (`1` to `12` weeks), complete-week windows (Sunday to Saturday), per-step colored series
- Overdue behavior with hierarchy:
  - global default (`workflow_overdue_days_default`)
  - workflow override
  - step override
  - `0` disables overdue behavior at that scope
- Workflow overdue indicator column in the workflow topic list
- Stale state transition handling with explicit user-facing error and automatic refresh
- Transition audit trail via small action posts
- Workflow visualization modal from topic and list links
- Data Explorer audit query support
- Data Explorer workflow stats query support for chart-oriented time series
- Optional AI-assisted step handling with prompt + option guardrails

## Quickstart

1. Enable the plugin in Site Settings (`workflow_enabled`).
2. Go to `Admin -> Plugins -> Discourse Workflow`, create a Workflow, then save it.
3. Add Workflow Steps (Categories in journey order), then add Step Options (actions/transitions).
4. Create a Topic in the first step Category and transition it through actions from the topic banner.
5. Use `/workflow` to view queue state, apply quick filters, and switch between `List` / `Kanban` / `Chart` views when available.
6. In Kanban, click a card to open the topic, drag cards to legal target steps, or use keyboard arrows on focused cards.
7. Use `/workflow/charts` (or `Chart` view in `/workflow`) to see step counts over time for the currently scoped single workflow.

## Setup

### Core plugin settings

- `workflow_enabled`: enables/disables workflow behavior.
- `workflow_overdue_days_default`: default overdue threshold in days; `0` disables overdue by default.
- `workflow_openai_api_key`: API key for AI actions.
- `workflow_ai_model`: model used for AI actions.
- `workflow_ai_prompt_system`: system prompt support for AI transitions.
- `workflow_charts_allowed_groups`: non-admin groups allowed to view workflow charts.

### Workflow definition setup

The workflow plugin is not bundled with a workflow; you create your own definitions.

The screens to create one are in `Admin -> Plugins -> Discourse Workflow`.

First create a new Workflow by hitting the button, save it, then populate it with Steps by editing the workflow. Each Step, once created, can be edited to add Options, taken from a list of pre-defined Options.

You can change the label of an Option in `Admin -> Customize -> Text`.

A good range of Options is seeded by default, but you can customize the text as needed.

Workflow-level Kanban controls:

- `show_kanban_tags`: controls whether tags render on Kanban cards below the title. Default is enabled.

### Overdue setup hierarchy

- Global default: `workflow_overdue_days_default`
- Optional workflow-level override: `Workflow.overdue_days`
- Optional step-level override: `WorkflowStep.overdue_days`

Resolution order is `step -> workflow -> global`. A value of `0` means overdue behavior is disabled at that level.

### Kanban compatibility and behavior

Kanban view is shown when the current `/workflow` list is scoped to a single compatible workflow.

Compatibility requires:

- at least one step
- a single start step at position `1`
- unique step positions
- valid target step IDs
- all steps reachable from the start step
- unique directed transition mapping per step pair (`from_step -> to_step`)

For each directed edge, Kanban drag/keyboard transitions are option-agnostic and deterministic.

### Chart view behavior and access model

Chart view is shown when the current workflow discovery context resolves to a single workflow.

- Route support: `/workflow/charts` and chart mode in `/workflow` via `workflow_view=chart`
- View selector behavior: `Chart` is only shown when the user can view charts and the current discovery context is a single workflow
- Period selection: `1` to `12` weeks
- Time windows: complete weeks (Sunday through Saturday)
- Series: one line per step, color derived from step category color (or parent category color fallback)
- Response scope: chart payload includes selected workflow metadata (`selected_workflow_id`, `selected_workflow_name`) plus series data for that selected workflow context

Access model for charts is intentionally separate from topic-level category access:

- Admins can always view charts
- Users in `workflow_charts_allowed_groups` can view charts
- Chart access is aggregate and workflow-level; it is intentionally not constrained to per-topic visibility rules
- This allows operational/reporting audiences to monitor workflow throughput without granting direct access to every underlying topic

If you want stricter chart data visibility, keep `workflow_charts_allowed_groups` empty and rely on admin-only access.

### Background jobs

The plugin schedules and runs the following jobs:

- `Jobs::DiscourseWorkflow::DailyStats`: records daily workflow step counts
- `Jobs::DiscourseWorkflow::AiTransitions`: runs AI-enabled transitions
- `Jobs::DiscourseWorkflow::DataExplorerQueriesCompleteness`: ensures default workflow Data Explorer queries exist
- `Jobs::DiscourseWorkflow::TopicArrivalNotifier`: sends first-post arrival notifications on workflow transitions

### AI actions

You can leverage AI to handle a step. You need `workflow_openai_api_key`, AI enabled on the step, and a prompt including both `{{options}}` and `{{topic}}`. You can also tune behavior with `workflow_ai_model` and `workflow_ai_prompt_system`.

Example prompt:

`your options are {{options}}. if the following text states it is delicious, please accept, otherwise reject. {{topic}} answer with one word from those options`

## Introductory Concepts

To leverage the Discourse platform as-is as much as possible, this plugin uses many existing core features.

## Swim Lanes

Each Workflow swim-lane is a Category (or Sub-Category).

As an instance of a workflow continues along its journey it moves between Categories in a customizable but pre-defined journey.

## Workflow Instances

A single instance of a workflow (e.g. a ticket) is a Topic. You can add tags to a Topic to highlight priority or other metadata. You cannot amend its Category once it has begun its journey other than by taking workflow actions upon the Topic.

## Actors

Any Group which has Topic creation access to a Category can act upon the topics in that Category.

Those that have Reply access can comment on the Workflow item just as they can for a normal Topic.

You can hide Topics within a Category from specific groups in the normal way.

## Actions via Options

These are defined for each step when setting up the Workflow. Actors can choose to take any available action as each Option is presented as a button on the Topic.

Actions on a Topic are captured in a Small Action Post to help users understand the journey of the Topic.

## Dashboard

A Topic Discovery filter `Workflow` gives a list of workflow instances (special workflow topics), with three presentation modes when available:

- `List`: sortable workflow topic list with workflow columns and quick filters
- `Kanban`: actionable card board for compatible single-workflow views
- `Chart`: step count trends over time for a single workflow

You should keep Workflow Categories and ideally tags distinct, so you can also use those to filter for all workflow instances that are at a particular stage, or have a specific tag.

## Audit trail

A bundled Data Explorer query provides a basic audit report of a workflow instance journey.

Because Data Explorer queries can be exposed beyond Admin, you can choose who to show them to.

## Visualisation

There is a button on each workflow Topic that allows you to bring up a visualization of where the Topic is in its workflow.

This is also accessible from the workflow fields on the Workflow Discovery Dashboard.

## Major Differences In Behavior To Stock

- you can't create a new Topic in a Category that's beyond the first step of a workflow
- you can't change the Category of a Topic that is within a workflow
- only "Creators" can act upon a Topic in a Workflow.

## Tips

- Consider making all workflow steps for a particular workflow a Subcategory within a single Category. Whilst this isn't necessary it will allow you to simply filter for that Category using existing Discourse Category drop-down in the Discovery list to see all workflow instances for that specific workflow.
- In the new Workflow Discovery list you can click on Workflow Name, Position or Step to visualise where that instance is along its path.

## Roadmap Themes

Status legend:

- `Implemented`: shipped and production-usable
- `Partial`: available in a limited form; still needs first-class completion
- `Planned`: supported by architecture direction but not shipped yet
- `Missing`: not yet represented as a first-class capability

Permissioning principle:

- The plugin intentionally reuses core Discourse category permissions as the default and preferred model.
- Finer-grained step/action permission controls are lower priority so the workflow system stays simple to operate, easy for admins to reason about, and close to standard Discourse behavior.

| Area        | Capability                                                    | Status      | Notes                                                                      |
| ----------- | ------------------------------------------------------------- | ----------- | -------------------------------------------------------------------------- |
| Definition  | Workflow definitions (steps/options mapped to categories)     | Implemented | Core admin CRUD plus workflow-level display controls (for example `show_kanban_tags`) |
| Runtime     | Topic transitions with audit posts                            | Implemented | Transition actions are logged in-topic                                     |
| Discovery   | Workflow list with quick filters, list/kanban toggle, and step filtering | Implemented | `/workflow` supports SPA quick filters plus list/kanban switching          |
| Discovery   | Real-time workflow state-change notifier with refresh CTA     | Planned     | Wire MessageBus updates into `/workflow` with a core-style “press to refresh” flow |
| Kanban      | Card transitions (drag/drop and keyboard arrows)              | Implemented | Legal transitions only; deterministic directed edge mapping                |
| SLA         | Overdue thresholds (step -> workflow -> global, `0` disables) | Implemented | Includes overdue list indicator                                            |
| Permissions | Native Discourse category permissions for acting/commenting   | Implemented | Transition authority still aligns with category create access              |
| Permissions | Step/action-level transition permissions                      | Partial     | Deliberately lower priority to preserve simple, core-aligned permissioning |
| Validation  | Transition preconditions (required tags/fields/checks)        | Planned     | Intended as optional guardrails before transitions                         |
| SLA         | Escalation/reminder notifications                             | Partial     | Overdue visibility exists; automated escalation is next                    |
| Ownership   | Discourse Assign integration                                  | Planned     | Target is step-entry assignment and auditable ownership changes            |
| Operations  | Bulk workflow transitions from list views                     | Missing     | High-volume queue operation not yet first-class                            |
| Performance | Eliminate admin serialization N+1 queries                     | Planned     | Preload workflow step/category associations in admin payloads for large workflow edit/list screens |
| Reporting   | Built-in workflow analytics dashboards                        | Partial     | Data Explorer support exists; admin-native reporting is next               |
| Lifecycle   | Import/export/version workflow definitions                    | Missing     | Useful for staging->production promotion and rollback                      |
| Integration | Event hooks / webhooks / automation integration               | Planned     | Transition and step events are good integration points                     |
| AI          | Guardrailed AI-assisted transitions                           | Partial     | Present but should tighten confidence/fallback/audit behavior              |

### Priority Roadmap

1. Add MessageBus-driven workflow state-change notifications with a core-style refresh CTA in `/workflow`.
2. Add transition preconditions and clearer per-action validation feedback.
3. Add escalation automation (reminders/alerts) on top of existing overdue thresholds.
4. Add first-class reporting and assignment integration for operational workflows.
5. Add definition lifecycle tooling (import/export/versioning) for safe environment promotion.
6. Keep advanced step/action permission granularity as a lower-priority enhancement to avoid unnecessary complexity versus native Discourse permissioning.
