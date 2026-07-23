<!-- hash:5555 -->
article_form_controller.js: Thin orchestrator → 7 modules (Autosave, UI, Draft, Content, Currency, Readiness, Conflict). 19 targets, 15 values. Lifecycle: init modules in initialize(), add/remove listeners in connect/disconnect. Proxy callbacks to modules. Shared helpers: setSaveStatus, contentValue, confirmLeaving.
