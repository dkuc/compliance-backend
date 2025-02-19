# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_01_20_125405) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "dblink"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "account_number"
    t.boolean "is_internal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "org_id", null: false
    t.index ["account_number"], name: "index_accounts_on_account_number", unique: true
    t.index ["org_id"], name: "index_accounts_on_org_id", unique: true
  end

  create_table "benchmarks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "version", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "package_name"
    t.index ["ref_id", "version"], name: "index_benchmarks_on_ref_id_and_version", unique: true
  end

  create_table "business_objectives", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_business_objectives_on_title"
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "business_objective_id"
    t.float "compliance_threshold", default: 100.0
    t.string "name"
    t.string "description"
    t.uuid "account_id"
    t.integer "total_host_count", default: 0, null: false
    t.integer "test_result_host_count", default: 0, null: false
    t.integer "compliant_host_count", default: 0, null: false
    t.integer "unsupported_host_count", default: 0, null: false
    t.index ["account_id"], name: "index_policies_on_account_id"
    t.index ["business_objective_id"], name: "index_policies_on_business_objective_id"
  end

  create_table "policy_hosts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "policy_id", null: false
    t.uuid "host_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["host_id"], name: "index_policy_hosts_on_host_id"
    t.index ["policy_id", "host_id"], name: "index_policy_hosts_on_policy_id_and_host_id", unique: true
    t.index ["policy_id"], name: "index_policy_hosts_on_policy_id"
  end

  create_table "profile_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "profile_id", null: false
    t.uuid "rule_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["profile_id", "rule_id"], name: "index_profile_rules_on_profile_id_and_rule_id", unique: true
    t.index ["profile_id"], name: "index_profile_rules_on_profile_id"
    t.index ["rule_id"], name: "index_profile_rules_on_rule_id"
  end

  create_table "profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "ref_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.uuid "account_id"
    t.uuid "benchmark_id", null: false
    t.uuid "parent_profile_id"
    t.boolean "external", default: false, null: false
    t.uuid "policy_id"
    t.string "os_minor_version", default: "", null: false
    t.decimal "score"
    t.boolean "upstream"
    t.jsonb "value_overrides", default: {}
    t.index ["account_id"], name: "index_profiles_on_account_id"
    t.index ["external"], name: "index_profiles_on_external"
    t.index ["name"], name: "index_profiles_on_name"
    t.index ["os_minor_version"], name: "index_profiles_on_os_minor_version"
    t.index ["parent_profile_id"], name: "index_profiles_on_parent_profile_id"
    t.index ["policy_id"], name: "index_profiles_on_policy_id"
    t.index ["ref_id", "account_id", "benchmark_id", "os_minor_version", "policy_id"], name: "uniqueness", unique: true
    t.index ["ref_id", "benchmark_id"], name: "index_profiles_on_ref_id_and_benchmark_id", unique: true, where: "(parent_profile_id IS NULL)"
    t.index ["upstream"], name: "index_profiles_on_upstream"
  end

  create_table "revisions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "revision", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_revisions_on_name", unique: true
  end

  create_table "rule_group_relationships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "left_type"
    t.uuid "left_id"
    t.string "right_type"
    t.uuid "right_id"
    t.string "relationship"
    t.index ["left_id", "right_id", "right_type", "left_type", "relationship"], name: "index_rule_group_relationships_unique", unique: true
    t.index ["left_type", "left_id"], name: "index_rule_group_relationships_on_left"
    t.index ["right_type", "right_id"], name: "index_rule_group_relationships_on_right"
  end

  create_table "rule_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id"
    t.string "title"
    t.text "description"
    t.text "rationale"
    t.string "ancestry"
    t.uuid "benchmark_id", null: false
    t.uuid "rule_id"
    t.integer "precedence"
    t.index ["ancestry"], name: "index_rule_groups_on_ancestry"
    t.index ["benchmark_id"], name: "index_rule_groups_on_benchmark_id"
    t.index ["precedence"], name: "index_rule_groups_on_precedence"
    t.index ["ref_id", "benchmark_id"], name: "index_rule_groups_on_ref_id_and_benchmark_id", unique: true
    t.index ["rule_id"], name: "index_rule_groups_on_rule_id", unique: true
  end

  create_table "rule_references_containers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "rule_id", null: false
    t.jsonb "rule_references"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rule_id"], name: "index_rule_references_containers_on_rule_id", unique: true
    t.index ["rule_references"], name: "index_rule_references_containers_on_rule_references", opclass: :jsonb_path_ops, using: :gin
  end

  create_table "rule_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "host_id"
    t.uuid "rule_id"
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "test_result_id"
    t.index ["host_id", "rule_id", "test_result_id"], name: "index_rule_results_on_host_id_and_rule_id_and_test_result_id", unique: true
    t.index ["host_id"], name: "index_rule_results_on_host_id"
    t.index ["rule_id"], name: "index_rule_results_on_rule_id"
    t.index ["test_result_id"], name: "index_rule_results_on_test_result_id"
  end

  create_table "rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id"
    t.boolean "supported"
    t.string "title"
    t.string "severity"
    t.text "description"
    t.text "rationale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.boolean "remediation_available", default: false, null: false
    t.uuid "benchmark_id", null: false
    t.boolean "upstream", default: true, null: false
    t.integer "precedence"
    t.uuid "rule_group_id"
    t.uuid "value_checks", default: [], array: true
    t.jsonb "identifier"
    t.index "((identifier -> 'label'::text))", name: "index_rules_on_identifier_labels", using: :gin
    t.index ["precedence"], name: "index_rules_on_precedence"
    t.index ["ref_id", "benchmark_id"], name: "index_rules_on_ref_id_and_benchmark_id", unique: true
    t.index ["ref_id"], name: "index_rules_on_ref_id"
    t.index ["slug", "benchmark_id"], name: "index_rules_on_slug_and_benchmark_id", unique: true
    t.index ["upstream"], name: "index_rules_on_upstream"
  end

  create_table "test_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.decimal "score"
    t.uuid "profile_id"
    t.uuid "host_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "supported", default: true
    t.index ["host_id", "profile_id", "end_time"], name: "index_test_results_on_host_id_and_profile_id_and_end_time", unique: true
    t.index ["host_id"], name: "index_test_results_on_host_id"
    t.index ["profile_id"], name: "index_test_results_on_profile_id"
    t.index ["supported"], name: "index_test_results_on_supported"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "redhat_id"
    t.string "redhat_org_id"
    t.string "lang"
    t.string "locale"
    t.string "username"
    t.boolean "internal"
    t.boolean "active"
    t.boolean "org_admin"
    t.uuid "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  create_table "value_definitions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ref_id"
    t.string "title"
    t.text "description"
    t.string "value_type"
    t.string "default_value"
    t.decimal "lower_bound"
    t.decimal "upper_bound"
    t.uuid "benchmark_id", null: false
    t.index ["benchmark_id"], name: "index_value_definitions_on_benchmark_id"
    t.index ["ref_id", "benchmark_id"], name: "index_value_definitions_on_ref_id_and_benchmark_id", unique: true
  end

  add_foreign_key "policies", "accounts"
  add_foreign_key "policies", "business_objectives"
  add_foreign_key "policy_hosts", "policies"
  add_foreign_key "profiles", "policies"
  add_foreign_key "profiles", "profiles", column: "parent_profile_id"
  add_foreign_key "rule_groups", "benchmarks"
  add_foreign_key "rule_groups", "rules"
  add_foreign_key "rule_references_containers", "rules"
  add_foreign_key "rules", "rule_groups"
  add_foreign_key "value_definitions", "benchmarks"
end
