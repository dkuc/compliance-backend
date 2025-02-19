# frozen_string_literal: true

module Insights
  module API
    module Common
      # Additional helper methods for audit logging
      class LoggerWithAudit < ActiveSupport::Logger
        def audit_success(message)
          tagged('AUDIT - SUCCESS').info(message)
        end

        def audit_fail(message)
          tagged('AUDIT - FAIL').info(message)
        end
      end
    end
  end
end
