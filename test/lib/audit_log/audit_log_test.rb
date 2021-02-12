# frozen_string_literal: true

require 'test_helper'
require 'audit_log/audit_log'

class AuditLogTest < ActiveSupport::TestCase
  test 'new wraps base logger' do
    base_logger = Logger.new(StringIO.new)
    wrapped = Insights::API::Common::AuditLog.new(base_logger)
    assert wrapped.respond_to?(:debug)
    assert wrapped.respond_to?(:info)
    assert wrapped.respond_to?(:warn)
    assert wrapped.respond_to?(:error)
    assert wrapped.respond_to?(:fatal)
    assert wrapped.respond_to?(:audit)
    assert wrapped.respond_to?(:audit_success)
    assert wrapped.respond_to?(:audit_fail)
  end

  test 'setting account number context' do
    begin
      Insights::API::Common::AuditLog.audit_with_account('1')
      assert_equal '1', Thread.current[:audit_account_number]

      Insights::API::Common::AuditLog.audit_with_account('2') do
        assert_equal '2', Thread.current[:audit_account_number]
      end

      assert_equal '1', Thread.current[:audit_account_number]
    ensure
      Thread.current[:audit_account_number] = nil
    end
  end
end
