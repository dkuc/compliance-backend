# frozen_string_literal: true

# Stores information about rules, such as which profiles can it be
# found in, what hosts are associated with it, etceter
class Rule < ApplicationRecord
  SORTED_SEVERITIES = Arel.sql(
    Arel::Nodes::Case.new.when(
      Rule.arel_table[:severity].eq(Arel::Nodes::Quoted.new('high'))
    ).then(3).when(
      Rule.arel_table[:severity].eq(Arel::Nodes::Quoted.new('medium'))
    ).then(2).when(
      Rule.arel_table[:severity].eq(Arel::Nodes::Quoted.new('low'))
    ).then(1).else(0).to_sql
  )

  sortable_by :title
  sortable_by :precedence
  sortable_by :severity, SORTED_SEVERITIES
  sortable_by :remediation_available

  extend FriendlyId
  friendly_id :ref_id, use: %i[slugged scoped], scope: :benchmark_id
  scoped_search on: %i[id severity], only_explicit: true
  scoped_search on: :ref_id
  scoped_search on: :identifier, aliases: %i[rule_identifier], only_explicit: true,
                ext_method: 'filter_by_identifier', operators: ['=', '!=']
  scoped_search on: :references, aliases: %i[rule_references reference], only_explicit: true,
                ext_method: 'filter_by_references', operators: ['=', '!=']
  include OpenscapParserDerived
  include RuleRemediation
  include ShortRefId

  has_many :profile_rules, dependent: :delete_all
  has_many :profiles, through: :profile_rules, source: :profile
  has_many :rule_results, dependent: :delete_all
  has_many :hosts, through: :rule_results, source: :host

  has_one :rule_references_container, dependent: :destroy

  has_many :left_rule_group_relationships, dependent: :delete_all, foreign_key: :left_id,
                                           inverse_of: :left, class_name: 'RuleGroupRelationship'
  has_many :right_rule_group_relationships, dependent: :delete_all, foreign_key: :right_id,
                                            inverse_of: :right, class_name: 'RuleGroupRelationship'
  belongs_to :benchmark, class_name: 'Xccdf::Benchmark'
  belongs_to :rule_group

  validates :title, presence: true
  validates :ref_id, uniqueness: { scope: %i[benchmark_id] }, presence: true
  validates :description, presence: true
  validates :severity, presence: true
  validates :benchmark_id, presence: true
  validates_associated :profile_rules
  validates_associated :rule_results

  alias_attribute :values, :value_checks

  scope :with_profiles, lambda {
    joins(:profile_rules).where.not(profile_rules: { profile_id: nil }).distinct
  }

  scope :latest, lambda {
    where(benchmark_id: ::Xccdf::Benchmark.latest.pluck(:id))
  }

  scope :canonical, lambda {
    joins(:profiles).where(profiles: { id: Profile.canonical })
  }

  scope :without_rule_group_parent, -> { where.missing(:rule_group) }

  def should_generate_new_friendly_id?
    # Automatic slug generation is happening in a validation callback, that forces activerecord-import
    # to run a query for each rule separately to ensure uniqueness. As the uniqueness of slugs is only
    # required per benchmark and they are already ensured by the source ref_id, it is safe to manually
    # generate friendly IDs when importing (see in self.from_openscap_parser).
    false
  end

  def canonical?
    (profiles & Profile.canonical).any?
  end

  # rubocop:disable Metrics/ParameterLists
  def self.from_openscap_parser(op_rule, existing: nil, rule_group_id: nil,
                                benchmark_id: nil, precedence: nil, value_checks: nil)
    rule = existing || new(ref_id: op_rule.id, benchmark_id: benchmark_id)

    rule.op_source = op_rule

    rule.assign_attributes(title: op_rule.title, description: op_rule.description,
                           rationale: op_rule.rationale, severity: op_rule.severity,
                           precedence: precedence, rule_group_id: rule_group_id,
                           upstream: false, slug: rule.normalize_friendly_id(op_rule.id),
                           value_checks: value_checks, identifier: op_rule.identifier&.to_h)

    rule
  end
  # rubocop:enable Metrics/ParameterLists

  def compliant?(host, profile)
    Rails.cache.fetch("#{id}/#{host.id}/compliant") do
      return false unless profile.present? && profile.rules.include?(self)

      latest_rule_result = latest_result(host, profile)
      return false if latest_rule_result.blank?

      %w[pass notapplicable notselected].include? latest_rule_result.result
    end
  end

  def latest_result(host, profile)
    test_result = TestResult.latest.find_by(profile_id: profile.id,
                                            host_id: host.id)
    return nil if test_result.blank?

    test_result.rule_results.find_by(rule_id: id)
  end

  def references
    # Try to reach for this in the cached attributes if possible
    attributes['references'] || rule_references_container&.rule_references
  end

  def self.filter_by_identifier(_filter, operator, value)
    { conditions: sanitize_sql_for_conditions(["rules.identifier ->> 'label' #{operator} ?", value]) }
  end

  def self.filter_by_references(_filter, operator, value)
    rules = RuleReferencesContainer.select(:rule_id).where(
      sanitize_sql_for_conditions(['rule_references @> ?::jsonb', [{ label: value }].to_json])
    )

    operator = operator == '!=' ? 'NOT' : ''

    { conditions: "rules.id #{operator} IN (#{rules.to_sql})" }
  end
end
