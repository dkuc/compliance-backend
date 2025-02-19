# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module Hosts
        extend Api::V1::Schemas::Util

        HOST = {
          type: 'object',
          required: %w[name],
          properties: {
            name: {
              type: 'string',
              example: 'console.redhat.com'
            },
            compliant: {
              type: 'boolean',
              example: true
            },
            has_policy: {
              type: 'boolean',
              example: true
            },
            os_major_version: {
              type: 'integer',
              example: 7,
              nullable: true
            },
            os_minor_version: {
              type: 'integer',
              example: 3,
              nullable: true
            },
            last_scanned: {
              type: 'string',
              example: '2020-06-04T19:31:55Z'
            },
            rules_passed: {
              type: 'integer',
              example: 34
            },
            rules_failed: {
              type: 'integer',
              example: 12
            },
            culled_timestamp: {
              type: 'string',
              example: '2020-06-04T19:31:55Z'
            },
            stale_warning_timestamp: {
              type: 'string',
              example: '2020-06-04T19:31:55Z'
            },
            stale_timestamp: {
              type: 'string',
              example: '2020-06-04T19:31:55Z'
            },
            updated: {
              type: 'string',
              example: '2020-06-04T19:31:55Z'
            },
            insights_id: {
              type: 'string',
              example: '374399b7-e6ba-49b7-a405-9b620a2bd0b3'
            }
          }
        }.freeze

        HOST_RELATIONSHIPS = {
          type: :object,
          properties: {
            profiles: ref_schema('relationship_collection'),
            test_results: ref_schema('relationship_collection')
          }
        }.freeze
      end
    end
  end
end
