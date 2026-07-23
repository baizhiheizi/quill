// Conflict resolution actions invoked from the article form UI when the
// server rejects an autosave with HTTP 409 (optimistic lock failure).
// `keepMyVersion` is the user-facing "keep mine" button; it re-syncs the
// lock_version meta and re-queues an autosave with the current draft.
// `removeConflictResolution` strips the conflict banner rendered into
// the DOM by the server's turbo-stream response.
export default class Conflict {
  constructor(controller) {
    this.controller = controller;
  }

  keepMyVersion() {
    this.controller.autosave.syncLockVersionFromMeta();
    this.controller.setSaveStatus("idle");
    this.removeConflictResolution();
    this.controller.autosave.queueAutosave();
  }

  removeConflictResolution() {
    document.getElementById("conflict-resolution")?.remove();
  }
}
