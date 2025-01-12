# frozen_string_literal: true
option_fixtures = [
  {
    name: 'Start',
    slug: 'start',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Submit',
    slug: 'submit',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Accept',
    slug: 'accept',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Reject',
    slug: 'reject',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name "Great",
    slug: 'great',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Good',
    slug: 'good',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Average',
    slug: 'average',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Poor',
    slug: 'poor',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Terrible',
    slug: 'terrible',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Done',
    slug: 'done',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Next',
    slug: 'next',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Previous',
    slug: 'previous',
    created_at: Time.now,
    updated_at: Time.now
  }
  {
    name: 'Close',
    slug: 'close',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Reopen',
    slug: 'reopen',
    created_at: Time.now,
    updated_at: Time.now
  },
  {
    name: 'Finish',
    slug: 'finish',
    created_at: Time.now,
    updated_at: Time.now
  }
]

if DiscourseWorkflow::WorkflowOption.count == 0
  DiscourseWorkflow::WorkflowOption.create!(option_fixtures)
  pp "Workflow options created"
end
