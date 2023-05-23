import { Controller } from '@hotwired/stimulus';
import { Editor, rootCtx, defaultValueCtx } from '@milkdown/core';
import { commonmark } from '@milkdown/preset-commonmark';
import { gfm } from '@milkdown/preset-gfm';
import { history } from '@milkdown/plugin-history';
import { block } from '@milkdown/plugin-block';
import { listener, listenerCtx } from '@milkdown/plugin-listener';
import { clipboard } from '@milkdown/plugin-clipboard';
import { Uploader } from '../javascript/utils/uploader';

export default class extends Controller {
  static targets = ['textarea', 'editor'];
  static values = {
    storageEndpoint: String,
    newRecord: Boolean,
    draftKey: String,
  };

  connect() {}

  editorTargetConnected() {
    this.prepareUploader();
    this.initEditor();
  }

  prepareUploader() {
    const imageInput = this.textareaTarget.querySelector(
      'input[data-direct-upload-url]',
    );
    if (imageInput) {
      const { directUploadUrl, directUploadToken, directUploadAttachmentName } =
        imageInput.dataset;
      this.uploader = new Uploader(
        directUploadUrl,
        directUploadToken,
        directUploadAttachmentName,
      );
    }
  }

  async initEditor() {
    const textarea = this.textareaTarget.querySelector('textarea');
    if (!textarea) return;

    const draft = localStorage.getItem(this.draftKeyValue);
    let content;
    if (this.newRecordValue && draft) {
      content = JSON.parse(draft);
    } else {
      content = textarea.textContent;
    }

    window.editor = await Editor.make()
      .config((ctx) => {
        ctx.set(rootCtx, this.editorTarget);
        ctx.set(defaultValueCtx, content);
      })
      .config((ctx) => {
        const listener = ctx.get(listenerCtx);
        listener.markdownUpdated((ctx, markdown, prevMarkdown) => {
          if (markdown !== prevMarkdown) {
            textarea.textContent = markdown;
            textarea.dispatchEvent(new Event('change'));
          }
        });
      })
      .use(clipboard)
      .use(commonmark)
      .use(gfm)
      .use(block)
      .use(history)
      .use(listener)
      .create();
  }
}
