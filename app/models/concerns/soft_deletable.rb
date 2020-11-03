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
    r || (raise ActiveRecord::RecordNotSaved.new('failed to soft delete the record', self))
  end

  def soft_delete
    _run_soft_delete { save }
  end

  def soft_undelete!
    r = _run_soft_undelete { save! }
    r || (raise ActiveRecord::RecordNotSaved.new('failed to soft undelete the record', self))
  end

  def soft_undelete
    _run_soft_undelete { save }
  end

  private

  def _run_soft_delete
    r = false
    f = lambda do
      self.deleted_at = Time.current
      r = yield
    end

    self.class.transaction do
      run_callbacks :soft_delete, &f
    end
    r
  end

  def _run_soft_undelete
    r = false
    f = lambda do
      self.deleted_at = nil
      r = yield
    end

    self.class.transaction do
      run_callbacks :soft_undelete, &f
    end
    r
  end
end
