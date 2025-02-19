# frozen_string_literal: true

require 'test_helper'

class CreateProfileMutationTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:user)
    @parent = FactoryBot.create(:canonical_profile, :with_rules)
    stub_rbac_permissions(Rbac::COMPLIANCE_ADMIN, Rbac::INVENTORY_VIEWER)
  end

  QUERY = <<-GRAPHQL
     mutation createProfile($input: createProfileInput!) {
        createProfile(input: $input) {
           profile {
               id
           }
        }
     }
  GRAPHQL

  test 'provide all required arguments' do
    result = Schema.execute(
      QUERY,
      variables: { input: {
        benchmarkId: @parent.benchmark_id,
        cloneFromProfileId: @parent.id,
        refId: 'xccdf-customized',
        name: 'customized profile',
        description: 'abcdf',
        complianceThreshold: 90.0
      } },
      context: { current_user: @user }
    )['data']['createProfile']['profile']

    cloned_profile = ::Profile.find(result['id'])
    assert cloned_profile.ref_id, 'xccdf-customized'
    assert_equal Set.new(cloned_profile.rules), Set.new(@parent.rules)
    assert_equal cloned_profile.parent_profile, @parent
  end

  test 'provide all required arguments and values' do
    vd = FactoryBot.create(:value_definition, benchmark: @parent.benchmark)
    result = Schema.execute(
      QUERY,
      variables: { input: {
        benchmarkId: @parent.benchmark_id,
        cloneFromProfileId: @parent.id,
        refId: 'xccdf-customized',
        name: 'customized profile',
        description: 'abcdf',
        complianceThreshold: 90.0,
        values: { vd.ref_id => 'foo' }
      } },
      context: { current_user: @user }
    )['data']['createProfile']['profile']

    cloned_profile = ::Profile.find(result['id'])
    assert_equal cloned_profile.values, { vd.id => 'foo' }
  end

  test 'provide all required arguments but invalid values' do
    assert_raises ActiveRecord::RecordNotFound do
      Schema.execute(
        QUERY,
        variables: { input: {
          benchmarkId: @parent.benchmark_id,
          cloneFromProfileId: @parent.id,
          refId: 'xccdf-customized',
          name: 'customized profile',
          description: 'abcdf',
          complianceThreshold: 90.0,
          values: { 'foo' => 'bar' }
        } },
        context: { current_user: @user }
      )['data']['createProfile']['profile']
    end
  end

  test 'provide all required arguments with selectedRuleRefIds' do
    result = Schema.execute(
      QUERY,
      variables: { input: {
        benchmarkId: @parent.benchmark_id,
        cloneFromProfileId: @parent.id,
        refId: 'xccdf-customized',
        name: 'customized profile',
        description: 'abcdf',
        complianceThreshold: 90.0,
        selectedRuleRefIds: @parent.rules.map(&:ref_id)
      } },
      context: { current_user: @user }
    )['data']['createProfile']['profile']

    cloned_profile = ::Profile.find(result['id'])
    assert cloned_profile.ref_id, 'xccdf-customized'
    assert_equal Set.new(cloned_profile.rules), Set.new(@parent.rules)
    assert_equal cloned_profile.parent_profile, @parent
  end

  test 'tailoring the list of rules via selectedRules' do
    tailored_rules = @parent.rules.sample(2).map(&:ref_id)

    assert_audited_success 'Created policy'
    assert_audited_success 'Updated tailoring of profile', "#{tailored_rules.count} rules added", '0 rules removed'
    result = Schema.execute(
      QUERY,
      variables: { input: {
        benchmarkId: @parent.benchmark_id,
        cloneFromProfileId: @parent.id,
        refId: 'xccdf-customized',
        name: 'customized profile',
        description: 'abcdf',
        complianceThreshold: 90.0,
        selectedRuleRefIds: tailored_rules
      } },
      context: { current_user: @user }
    )['data']['createProfile']['profile']

    cloned_profile = ::Profile.find(result['id'])
    assert cloned_profile.ref_id, 'xccdf-customized'
    assert_not_equal cloned_profile.rules, @parent.rules
    assert_equal Set.new(cloned_profile.rules),
                 Set.new(Rule.where(ref_id: tailored_rules))
    assert_equal cloned_profile.parent_profile, @parent
  end
end
