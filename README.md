# discourse-workflow

A workflow tool for Discourse!

# Summary

A plugin which provides a secure workflow framework for Topics which are passed along a customisable set of steps until the worklfow is complete.  Some branching and looping is supported.

# Introductory concepts

To leverage the Discourse platform as is as much as possible I've created a simple framework that uses many existing features of the platform.

## Swim Lanes

Each Workflow swim-lane is a Category (or Sub-Category).

As an instance of a workflow continues along its journey it moves between Categories in a customisable but pre-defined journey.

## Workflow Instances

A single instance of a workflow (e.g. a ticket) is a Topic.  You can add tags to a Topic to highlight its priority or other meta-data.  You cannot amend its Category once it has begun its journey other than by taking workflow actions upon the Topic.

## Actors

Any Group which has Topic creation access to a Category can act upon the topics in that Category.

Those that have Reply access can comment on the Workflow item just as they can for a normal Topic.

You can hide Topics within a Category from specific groups in the normal way.

## Actions aka Options

These are defined for each step when setting up the Workflow.  Actors can choose to take any available action as each Option is presented as a button on the Topic.

## Dashboard

A new Topic Discovery filter "Workflows" on the homepage gives a list of Workflow intances (special workflow topics)

## Audit trail

A bundled Data Explorer query provides a basic audit report of journey a worklfow instance has taken.

Because Data Explorer queries can be exposed to user beyond Admin, you can choose who to show them to.

## Visualisation

There is a button on each workflow Topic that allows you to bring up a a visualisation of where the Topic is in its workflow

This is also accessible from the workflow fields on the Workflow Discovery Dashboard.

# Major differences in behaviour to stock

- you can't create a new Topic in a Category that's beyond the first step of a workflow
- you can't change the Category of a Topic that is within a workflow
- only "Creators" can act upon a Topic in a Workflow.

# Getting Started.

The workflow plugin is not bundled with a Workflow, you have to create one.

The screens to create one are in the Admin -> Plugins -> Discourse Workflow.

First create a new Workflow by hitting the button, save it, then populate it with Steps by Editing the workflow.  Each Step, once created, can have be Edited to add Options, taken from a list of pre-defined Options.

You can change the label of an Option in Admin -> Customize -> Text.

I've seeded the system with a good range of Options, but if you wish to change the text on each one, go ahead.