# frozen_string_literal: true

require_relative 'interfaces/rules_preload'
require_relative 'concerns/test_results'
require_relative 'concerns/profile_pseudo_policy'

module Types
  # Definition of the Profile type in GraphQL
  class Profile < Types::BaseObject
    include Concerns::TestResults
    include Concerns::ProfilePseudoPolicy

    implements(Interfaces::RulesPreload)

    graphql_name 'Profile'
    description 'A Profile registered in Insights Compliance'

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :ref_id, String, null: false
    field :compliance_threshold, Float, null: false
    field :benchmark_id, ID, null: false
    field :account_id, ID, null: false
    field :policy, Types::Profile, null: true
    field :profiles, [::Types::Profile], null: true
    field :rules, [::Types::Rule], null: true, extras: [:lookahead] do
      argument :system_id, String, 'System ID to filter by', required: false
      argument :identifier, String, 'Rule identifier to filter by', required: false
      argument :references, [String], 'Rule references to filter by', required: false
    end
    field :top_failed_rules, [::Types::Rule], null: true do
      argument :policy_id, ID, 'Policy ID to filter by', required: true
    end
    field :hosts, [::Types::System], null: true
    field :benchmark, ::Types::Benchmark, null: true
    field :ssg_version, String, null: false
    field :values, GraphQL::Types::JSON, null: true
    field :supported_os_versions, [String], null: false
    field :business_objective, ::Types::BusinessObjective, null: true
    field :business_objective_id, ID, null: true
    field :total_host_count, Int, null: false
    field :test_result_host_count, Int, null: false
    field :unsupported_host_count, Int, null: false
    field :external, Boolean, null: false
    field :parent_profile_id, ID, null: true
    field :in_use, Boolean, null: true

    field :score, Float, null: false do
      argument :system_id, String,
               'Latest TestResult score for this system and profile',
               required: false
    end

    field :supported, Boolean, null: false do
      argument :system_id, String,
               'Latest TestResult supported for this system and profile',
               required: false
    end

    field :compliant, Boolean, null: false do
      argument :system_id, String, 'Is a system compliant with this profile?',
               required: false
    end

    field :rules_passed, Int, null: false do
      argument :system_id, String,
               'Rules passed for a system and a profile', required: false
    end

    field :rules_failed, Int, null: false do
      argument :system_id, String,
               'Rules failed for a system and a profile', required: false
    end

    field :last_scanned, String, null: false do
      argument :system_id, String,
               'Last time this profile was scanned for a system', required: false
    end

    field :compliant_host_count, Int, null: false

    field :os_major_version, String, null: false
    field :os_minor_version, String, null: false
    field :os_version, String, null: false
    field :policy_type, String, null: false

    enforce_rbac Rbac::POLICY_READ

    def last_scanned(args = {})
      latest_test_result_batch(args).then do |latest_test_result|
        if latest_test_result.blank? || latest_test_result.end_time.blank?
          'Never'
        else
          latest_test_result.end_time.iso8601
        end
      end
    end

    def hosts
      ::CollectionLoader.for(policy_or_report.class, :hosts).load(policy_or_report)
    end

    def benchmark
      ::CollectionLoader.for(::Profile, :benchmark).load(object)
    end

    # When listing supportedProfiles to properly mark the profile as already in use
    def in_use
      object.in_use if object.has_attribute?(:in_use)
    end

    private

    def policy_or_report
      object.policy || object
    end

    def system_id(args)
      args[:system_id] || context[:parent_system_id]
    end

    def latest_test_result_batch(args)
      ::RecordLoader.for(::TestResult, column: :host_id, where: { profile_id: object.id },
                                       order: 'created_at DESC').load(system_id(args))
    end
  end
end
