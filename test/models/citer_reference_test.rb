# frozen_string_literal: true

require "test_helper"

class CiterReferenceTest < ActiveSupport::TestCase
  test "creates a valid reference between two articles" do
    citer = articles(:published_paid)
    reference = articles(:published_free)

    reference_record = CiterReference.create!(
      citer: citer,
      reference: reference,
      revenue_ratio: 0.05
    )

    assert reference_record.persisted?
    assert_equal citer, reference_record.citer
    assert_equal reference, reference_record.reference
    assert_in_delta 0.05, reference_record.revenue_ratio
  end

  test "citer can reference multiple articles" do
    citer = articles(:published_paid)
    ref1 = articles(:published_free)
    ref2 = articles(:high_revenue)

    CiterReference.create!(citer: citer, reference: ref1, revenue_ratio: 0.05)
    CiterReference.create!(citer: citer, reference: ref2, revenue_ratio: 0.03)

    assert_equal 2, citer.article_references.count
  end

  test "multiple citers can reference the same article" do
    citer1 = articles(:published_paid)
    citer2 = articles(:high_revenue)
    reference = articles(:published_free)

    CiterReference.create!(citer: citer1, reference: reference, revenue_ratio: 0.05)
    CiterReference.create!(citer: citer2, reference: reference, revenue_ratio: 0.03)

    assert_equal 2, reference.article_citers.count
  end

  test "uniqueness validation prevents duplicate references" do
    citer = articles(:published_paid)
    reference = articles(:published_free)

    CiterReference.create!(citer: citer, reference: reference, revenue_ratio: 0.05)

    duplicate = CiterReference.new(citer: citer, reference: reference, revenue_ratio: 0.10)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:reference_id], "already been taken"
  end

  test "same citer cannot reference same article with different revenue_ratio if unique constraint is scope-based" do
    citer = articles(:published_paid)
    reference = articles(:published_free)

    # The uniqueness scope is [citer_id, citer_type, reference_id, reference_type]
    # So attempting to create a second reference with the same scope fails
    CiterReference.create!(citer: citer, reference: reference, revenue_ratio: 0.05)

    second_reference = CiterReference.new(citer: citer, reference: reference, revenue_ratio: 0.10)
    assert_not second_reference.valid?
  end

  test "revenue_ratio is required" do
    citer = articles(:published_paid)
    reference = articles(:published_free)

    reference_record = CiterReference.new(citer: citer, reference: reference, revenue_ratio: nil)
    assert_not reference_record.valid?
    assert_includes reference_record.errors[:revenue_ratio], "can't be blank"
  end

  test "citer_type and reference_type are set automatically from polymorphic association" do
    citer = articles(:published_paid)
    reference = articles(:published_free)

    reference_record = CiterReference.create!(
      citer: citer,
      reference: reference,
      revenue_ratio: 0.05
    )

    assert_equal "Article", reference_record.citer_type
    assert_equal "Article", reference_record.reference_type
  end
end
