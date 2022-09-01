import { Controller } from '@hotwired/stimulus';
import { Editor, isTextSelection } from '@tiptap/core';
import StarterKit from '@tiptap/starter-kit';
import Image from '@tiptap/extension-image';
import { createMarkdownEditor } from 'tiptap-markdown';
import Typography from '@tiptap/extension-typography';
import BubbleMenu from '@tiptap/extension-bubble-menu';
import FloatingMenu from '@tiptap/extension-floating-menu';
import Underline from '@tiptap/extension-underline';
import Placeholder from '@tiptap/extension-placeholder';
import Link from '@tiptap/extension-link';
import { showLoading, hideLoading } from '../javascript/utils';
import { Uploader } from '../javascript/utils/uploader';
import { debounce } from 'underscore';

export default class extends Controller {
  static values = {
    storageEndpoint: String,
    newRecord: Boolean,
    draftKey: String,
  };

  static targets = [
    'textarea',
    'editor',
    'bubbleMenu',
    'floatingMenu',
    'bubbleMenuButton',
    'bubbleMenuButtonGroup',
    'bubbleMenuLinkSetting',
    'setLinkInput',
  ];

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

  initEditor() {
    const textarea = this.textareaTarget.querySelector('textarea');
    if (!textarea) return;

    const draft = localStorage.getItem(this.draftKeyValue);
    let content;
    if (this.newRecordValue && draft) {
      content = JSON.parse(draft);
    } else {
      content = textarea.textContent;
    }

    const MdEditor = createMarkdownEditor(Editor);
    this.editor = new MdEditor({
      element: this.editorTarget,
      content,
      autofocus: true,
      markdown: {
        breaks: false,
      },
      extensions: [
        BubbleMenu.configure({
          element: this.bubbleMenuTarget,
          shouldShow: ({ editor, view, state, from, to }) => {
            const { doc, selection } = state;
            const { empty } = selection;
            const isEmptyTextBlock =
              !doc.textBetween(from, to).length &&
              isTextSelection(state.selection);

            if (!view.hasFocus() || empty || isEmptyTextBlock) {
              return false;
            }

            return !editor.isActive('image');
          },
        }),
        FloatingMenu.configure({
          element: this.floatingMenuTarget,
          tippyOptions: { placement: 'bottom-start' },
        }),
        Image.configure({ inline: false }),
        Link.configure({
          openOnClick: false,
        }),
        Placeholder.configure({ placeholder: textarea.placeholder }),
        StarterKit,
        Typography,
        Underline,
      ],
      editorProps: {
        attributes: {
          class:
            'prose dark:prose-invert prose-img:rounded-lg prose-img:shadow-md prose-img:mx-auto prose-pre:bg-zinc-100 prose-pre:text-black dark:prose-pre:bg-zinc-800 dark:prose-pre:text-zinc-100 xl:prose-lg mx-auto break-words focus:outline-none',
        },
        handlePaste: (view, event) => {
          const items = (
            event.clipboardData || event.originalEvent.clipboardData
          ).items;

          Array.from(items).forEach(async (item) => {
            const { schema } = view.state;
            const image = item.getAsFile();
            if (!image) return;

            event.preventDefault();
            const { key, filename } = await this.uploader.upload(image);
            const node = schema.nodes.image.create({
              src: `${this.storageEndpointValue}/${key}`,
              alt: filename,
            });

            const transaction = view.state.tr.replaceSelectionWith(node);
            view.dispatch(transaction);
          });
        },
      },
      onUpdate: ({ editor }) => {
        textarea.textContent = editor.getMarkdown();
        textarea.dispatchEvent(new Event('change'));
      },
    });
  }

  toggleBold() {
    this.editor.chain().focus().toggleBold().run();
  }

  bubbleMenuTargetConnected() {
    if (this.editor.isActive('link')) {
      this.setLinkInputTarget.value =
        this.editor.getAttributes('link').href || '';
      this.bubbleMenuLinkSettingTarget.classList.remove('hidden');
      this.bubbleMenuButtonGroupTarget.classList.add('hidden');
    } else {
      this.bubbleMenuLinkSettingTarget.classList.add('hidden');
      this.bubbleMenuButtonGroupTarget.classList.remove('hidden');
    }

    this.bubbleMenuButtonTargets.forEach((button) => {
      if (this.editor.isActive(button.dataset.buttonType)) {
        button.classList.add('bg-zinc-300');
      } else {
        button.classList.remove('bg-zinc-300');
      }
    });
  }

  toggleItalic(event) {
    event.preventDefault();
    this.editor.chain().focus().toggleItalic().run();
  }

  toggleStrike(event) {
    event.preventDefault();
    this.editor.chain().focus().toggleStrike().run();
  }

  toggleCode(event) {
    event.preventDefault();
    this.editor.chain().focus().toggleCode().run();
  }

  addHeading(event) {
    const { level } = event.params;
    this.editor.chain().focus().toggleHeading({ level }).run();
  }

  toggleLink(event) {
    event.preventDefault();
    this.setLinkInputTarget.value =
      this.editor.getAttributes('link').href || '';
    this.bubbleMenuButtonGroupTarget.classList.add('hidden');
    this.bubbleMenuLinkSettingTarget.classList.remove('hidden');
  }

  setLink(event) {
    event.preventDefault();
    const href = event.currentTarget.value;
    this.editor.chain().focus().extendMarkRange('link').setLink({ href }).run();
  }

  unsetLink(event) {
    event.preventDefault();
    this.bubbleMenuButtonGroupTarget.classList.remove('hidden');
    this.bubbleMenuLinkSettingTarget.classList.add('hidden');
    this.editor.chain().focus().extendMarkRange('link').unsetLink().run();
  }

  uploadImage(event) {
    event.preventDefault();
    Array.from(event.currentTarget.files).forEach(async (file) => {
      if (!file.type.match(/^image/)) return;

      showLoading();
      const { key, filename } = await this.uploader.upload(file);
      hideLoading();
      if (!key) return;

      this.editor
        .chain()
        .focus()
        .setImage({
          src: `${this.storageEndpointValue}/${key}`,
          alt: filename,
        })
        .run();
    });
  }

  addCodeBlock(event) {
    event.preventDefault();
    this.editor.chain().focus().toggleCodeBlock().run();
  }
}
