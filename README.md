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
- Overdue behavior with hierarchy:
  - global default (`workflow_overdue_days_default`)
  - workflow override
  - step override
  - `0` disables overdue behavior at that scope
- Workflow overdue indicator column in the workflow topic list
- Transition audit trail via small action posts
- Workflow visualization modal from topic and list links
- Data Explorer audit query support
- Optional AI-assisted step handling with prompt + option guardrails

## Quickstart

1. Enable the plugin in Site Settings (`workflow_enabled`).
2. Go to `Admin -> Plugins -> Discourse Workflow`, create a Workflow, then save it.
3. Add Workflow Steps (Categories in journey order), then add Step Options (actions/transitions).
4. Create a Topic in the first step Category and transition it through actions from the topic banner.
5. Use `/workflow` to view queue state, apply quick filters, and visualize progress.

## Setup

### Core plugin settings

- `workflow_enabled`: enables/disables workflow behavior.
- `workflow_overdue_days_default`: default overdue threshold in days; `0` disables overdue by default.
- `workflow_openai_api_key`: API key for AI actions.
- `workflow_ai_model`: model used for AI actions.
- `workflow_ai_prompt_system`: system prompt support for AI transitions.

### Workflow definition setup

The workflow plugin is not bundled with a workflow; you create your own definitions.

The screens to create one are in `Admin -> Plugins -> Discourse Workflow`.

First create a new Workflow by hitting the button, save it, then populate it with Steps by editing the workflow. Each Step, once created, can be edited to add Options, taken from a list of pre-defined Options.

You can change the label of an Option in `Admin -> Customize -> Text`.

A good range of Options is seeded by default, but you can customize the text as needed.

### Overdue setup hierarchy

- Global default: `workflow_overdue_days_default`
- Optional workflow-level override: `Workflow.overdue_days`
- Optional step-level override: `WorkflowStep.overdue_days`

Resolution order is `step -> workflow -> global`. A value of `0` means overdue behavior is disabled at that level.

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

These are defined for each step when setting up the Workflow.  Actors can choose to take any available action as each Option is presented as a button on the Topic.

Actions on a Topic are captured in a Small Action Post to help users understand the journey of the Topic.

## Dashboard

A Topic Discovery filter `Workflow` gives a list of workflow instances (special workflow topics).

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

- Step-level permissions and ownership: Keep category-based permissions as the default model, with optional finer-grained transition authorization where needed.
  - Current Discourse-native behavior already supports comment/review without transition: users with `Reply` (but not `Create`) can participate without acting on workflow transitions.
  - The gap appears when teams need to separate "can create new topics in this category" from "can transition existing workflow topics in this step."
  - Some workflows also need action-level control (for example, allow `accept` but restrict `reject`) without restructuring category permissions.
  - This should remain an advanced option layered on top of existing Discourse permissions, not a replacement.
- Transition preconditions: Allow workflows to require conditions before transition (for example required tags, required fields, checklists, or validation rules).
  - Why include this: many process steps depend on information completeness, and without guardrails topics can move forward with missing required data.
  - Possible enhancement: define per-step transition rules using existing Discourse primitives (tags, topic custom fields, checklist completion, post template markers).
  - Possible enhancement: return clear validation feedback in the action UI so users know exactly what must be completed before transition.
  - Possible enhancement: support staff bypass/audit options for urgent exceptions without removing the default guardrails.
- SLA and escalation workflows: Track time-in-step, surface ageing items, and support reminder/escalation notifications for stalled work.
  - Why include this: operational teams need visibility into ageing work items and service commitments, not only current position in the workflow.
  - Possible enhancement: persist timestamps for step entry/exit and compute time-in-step and overall cycle time.
  - Possible enhancement: provide configurable thresholds per step (warning, breach) and notify responsible users/groups using Discourse notifications.
  - Possible enhancement: expose SLA filters and badges in workflow topic lists so moderators can triage overdue items quickly.
- Assignment integration: Deeper alignment with Discourse Assign to support queue ownership, automatic assignment on arrival, and reassignment patterns.
  - Why include this: transitions and ownership are often coupled, and manual re-assignment at each step is repetitive and error-prone.
  - Possible enhancement: auto-assign to a user/group when entering a step, with optional round-robin or fallback assignee behavior.
  - Possible enhancement: support assignment rules per step while preserving existing Assign plugin UX and permissions.
  - Possible enhancement: record assignment changes alongside workflow transition logs for a complete operational audit trail.
- Bulk workflow operations: Support bulk transition and related moderation actions from workflow list views for high-volume operations.
  - Why include this: high-volume queues become inefficient if every transition must be performed topic-by-topic.
  - Possible enhancement: allow bulk selection in workflow discovery and apply a permitted transition action to all selected topics.
  - Possible enhancement: include dry-run previews showing how many selected topics are eligible vs blocked by permissions/preconditions.
  - Possible enhancement: combine with existing bulk moderation operations (tag, assign, close) for operational batching.
- First-class reporting: Provide built-in workflow analytics (throughput, lead time, bottlenecks, reopen rates) beyond Data Explorer defaults.
  - Why include this: Data Explorer is powerful but not always accessible or intuitive for non-technical admins.
  - Possible enhancement: add an admin report screen with key workflow KPIs per period and per step.
  - Possible enhancement: provide trend charts for throughput, average step duration, and backlog ageing using existing stats tables.
  - Possible enhancement: include exportable CSV views so teams can share metrics externally without writing custom SQL.
- Definition lifecycle tooling: Import/export and version workflow definitions to improve change control across environments.
  - Why include this: workflows often need promotion across staging/production and controlled rollback when process definitions change.
  - Possible enhancement: export/import workflow definitions as JSON including steps, options, and transition mappings.
  - Possible enhancement: store definition versions and show effective history for auditability and safer iterative changes.
  - Possible enhancement: validate imported definitions against current category/tag/site settings before applying.
- Event hooks and automations: Add automation/webhook hooks for step entry, step exit, and transitions to integrate with broader Discourse workflows.
  - Why include this: workflow transitions are high-value events that often need to trigger actions outside the plugin itself.
  - Possible enhancement: publish plugin events (step_entered, step_exited, transition_performed) with stable payloads.
  - Possible enhancement: provide first-class integration points for Discourse Automation recipes and outbound webhooks.
  - Possible enhancement: support idempotency keys/audit references so downstream systems can process events safely.
- Guardrailed AI transitions: Improve reliability with stricter option parsing, confidence/fallback handling, and stronger audit visibility for AI-driven actions.
  - Why include this: AI-assisted routing is useful, but incorrect transitions can be costly without safeguards and observability.
  - Possible enhancement: enforce strict option matching/parsing and reject responses that do not map cleanly to configured transition slugs.
  - Possible enhancement: add confidence thresholds and optional human-review fallback for low-confidence decisions.
  - Possible enhancement: log prompts, model outputs, and selected transitions in a dedicated audit stream (with privacy controls).
