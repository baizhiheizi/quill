# frozen_string_literal: true

# The dispatch verb every notification in the app goes through. A model states
# intent — the event (the notifier class), the record the notification is
# anchored to and its params — and `recipient:` names who receives it:
#
#     notify! ArticlePublishedNotifier,
#       recipient: Notifiers::Audience.subscribed_to(author, excluding_blocked: author),
#       article: self
#
# Audience resolution (subscribe / block / self-echo subqueries) lives in
# `Notifiers::Audience`, never inline at a call site, so the rules are shared
# instead of remembered. `recipient:` takes one user or many (a relation or an
# array) — it is the app-code twin of the single-recipient helper the test
# suite has always used (`NotifierHelpers#deliver_notifier!`), which delegates
# to the same `Notifiable.dispatch`.
module Notifiable
  extend ActiveSupport::Concern

  # The delivery primitive itself, shared by the instance verb and the test
  # helper so app code and suite cannot drift apart. `recipient` is passed to
  # `Noticed::Event#deliver` untouched, `nil` included — callers keep their own
  # guards (`Transfer#notify_recipient`, `Payment#notify_payer`).
  def self.dispatch(notifier, recipient:, record:, **params)
    notifier.with(record: record, **params).deliver(recipient)
  end

  # Dispatch one event. `record` defaults to the receiver, which is the right
  # anchor for every site that notifies about itself.
  def notify!(notifier, recipient:, record: self, **params)
    Notifiable.dispatch(notifier, recipient: recipient, record: record, **params)
  end
end
