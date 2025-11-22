# frozen_string_literal: true

module DiscourseWorkflow
  class AiActions
    def transition_all
      DiscourseWorkflow::WorkflowState
        .includes(:topic, workflow_step: { workflow_step_options: :workflow_option })
        .find_each do |workflow_state|

        step = workflow_state.workflow_step
        next unless step

        # skip if AI not enabled or no options
        next unless step.ai_enabled
        next if step.workflow_step_options.empty?

        ai_transition(workflow_state)
      end
    end

    def ai_transition(workflow_state)
      step  = workflow_state.workflow_step
      topic = workflow_state.topic
      return unless step && topic

      client        = OpenAI::Client.new(access_token: SiteSetting.workflow_openai_api_key)
      model_name    = SiteSetting.workflow_ai_model
      system_prompt = SiteSetting.workflow_ai_prompt_system
      base_user_prompt = step.ai_prompt

      return if base_user_prompt.blank?

      # get option slugs for this step
      options =
        step.workflow_step_options
            .includes(:workflow_option)
            .map { |o| o.workflow_option&.slug }
            .compact

      return if options.empty?

      user_prompt = base_user_prompt.gsub(/{{options}}/, options.join(", "))
      user_prompt = user_prompt.gsub(/{{topic}}/, topic.first_post.raw)

      messages = [
        { role: "system", content: system_prompt },
        { role: "user",   content: user_prompt }
      ]

      response = client.chat(
        parameters: {
          model:       model_name,
          messages:    messages,
          max_tokens:  8,
          temperature: 0.1
        }
      )

      if response["error"]
        begin
          raise StandardError, response["error"]["message"]
        rescue => e
          Rails.logger.error("Workflow: There was a problem: #{e}")
        end
        return
      end

      result = response.dig("choices", 0, "message", "content")
      result = result.strip.chomp(".").downcase if result.present?

      if result.present? && options.include?(result)
        Transition.new.transition(nil, topic, result)
      end
    end
  end
end
