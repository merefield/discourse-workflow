module DiscourseWorkflow
  class AiActions

    def transition_all
      WorkflowState.each do |workflow_state|
        if workflow_state.workflow_step.ai_enabled && workflow_state.workflow_step.workflow_step_option.count > 0
          ai_transition(workflow_state)
        end
      end
    end

    def ai_transition(workflow_state)
      client = OpenAI::Client.new(access_token: SiteSetting.workflow_openai_api_key)
      model_name = SiteSetting.workflow_ai_model
      byebug
  
      system_prompt =  SiteSetting.workflow_ai_prompt_system
      base_user_prompt =  workflow_state.workflow_step.ai_prompt

      return if !base_user_prompt.present?

      options = workflow_state.workflow_step.workflow_step_option.map(&:workflow_option)&.pluck(:slug)
      user_prompt = base_user_prompt.gsub(/{{options}}/, options.join(', '))
      topic = Topic.find(workflow_state.topic_id)
      user_prompt = user_prompt.gsub(/{{topic}}/, topic.first_post.raw)

      messages = [{ "role": "system", "content": system_prompt}]
      messages << { "role": "user", "content":  user_prompt }

      response = client.chat(
        parameters: {
            model: model_name,
            messages: messages,
            max_tokens: 8,
            temperature: 0.1,
        })
  
      if response["error"]
        begin
          raise StandardError, response["error"]["message"]
        rescue => e
          Rails.logger.error ("Workflow: There was a problem: #{e}")
          # I18n.t('ai_topic_summary.errors.general')
        end
      else
        result = response.dig("choices", 0, "message", "content")
      end

      result = result.strip.chomp('.').downcase if result.present?

      if result.present? && options.include?(result)
        Transition.new.transition(nil, topic, result)
      end
    end
  end
end
