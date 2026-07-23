# frozen_string_literal: true

module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :without_deleted, -> { where(deleted_at: nil) }
    scope :only_deleted, -> { unscope(where: :deleted_at).where.not(deleted_at: nil) }
    scope :with_deleted, -> { unscope(where: :deleted_at) }

    define_model_callbacks :soft_delete
    define_model_callbacks :soft_undelete
  end

  def deleted?
    deleted_at?
  end

  def soft_delete!
    r = _run_soft_delete { save! }
    r || (raise ActiveRecord::RecordNotSaved.new("failed to soft delete the record", self))
  end

  def soft_delete
    _run_soft_delete { save }
  end

  def soft_undelete!
    r = _run_soft_undelete { save! }
    r || (raise ActiveRecord::RecordNotSaved.new("failed to soft undelete the record", self))
  end

  def soft_undelete
    _run_soft_undelete { save }
  end

  private

  def run_soft_action(callback_name, deleted_at_value, &block)
    result = false
    action = -> { self.deleted_at = deleted_at_value; result = block.call }

    self.class.transaction do
      run_callbacks callback_name, &action
    end

    result
  end

  def _run_soft_delete(&block)
    run_soft_action(:soft_delete, Time.current, &block)
  end

  def _run_soft_undelete(&block)
    run_soft_action(:soft_undelete, nil, &block)
  end
end
