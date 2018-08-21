module AnsibleTowerClient
  class JobTemplate < BaseModel
    REQUIRED_ATTRIBUTES_FOR_OPTIONS = {
      :job_tags   => :ask_tags_on_launch,
      :job_type   => :ask_job_type_on_launch,
      :limit      => :ask_limit_on_launch,
      :inventory  => :ask_inventory_on_launch,
      :credential => :ask_credential_on_launch,
    }.freeze
    private_constant :REQUIRED_ATTRIBUTES_FOR_OPTIONS

    def launch(options = {})
      check_required_attributes_for_options(options)

      launch_url = "#{url}launch/"
      response   = api.post(launch_url, options).body
      job        = JSON.parse(response)

      api.jobs.find(job['job'])
    end

    def survey_spec
      spec_url = related['survey_spec']
      return nil unless spec_url
      api.get(spec_url).body
    rescue AnsibleTowerClient::UnlicensedFeatureError
    end

    def survey_spec_hash
      survey_spec.nil? ? {} : hashify(:survey_spec)
    end

    def extra_vars_hash
      extra_vars.empty? ? {} : hashify(:extra_vars)
    end

    def override_raw_attributes
      { :credential => :credential_id, :inventory => :inventory_id, :project => :project_id }
    end

    private

    def check_required_attributes_for_options(options)
      ignored_options = REQUIRED_ATTRIBUTES_FOR_OPTIONS.select do |option, checkmark|
        !try(checkmark) && options.slice(option.to_sym, option.to_s).any?(&:present?)
      end.keys

      return if ignored_options.empty?

      message = ignored_options.map(&:inspect).to_sentence
      message = ignored_options.size == 1 ? " #{message} is" : "s #{message} are"
      message = "Option#{message} provided but corresponding ask on launch flag has not been turn on"
      raise ArgumentError, message
    end
  end
end
