import { Controller } from '@hotwired/stimulus';
import { Editor, Extension } from '@tiptap/core';
import { Plugin, PluginKey } from 'prosemirror-state';
import StarterKit from '@tiptap/starter-kit';
import Image from '@tiptap/extension-image';
import { Markdown } from 'tiptap-markdown';
import Typography from '@tiptap/extension-typography';
import BubbleMenu from '@tiptap/extension-bubble-menu';
import FloatingMenu from '@tiptap/extension-floating-menu';
import Underline from '@tiptap/extension-underline';
import Placeholder from '@tiptap/extension-placeholder';
import Link from '@tiptap/extension-link';
import CodeBlockLowlight from '@tiptap/extension-code-block-lowlight';
import Highlight from '@tiptap/extension-highlight';
import { lowlight } from 'lowlight';
import { showLoading, hideLoading } from '../javascript/utils';
import { Uploader } from '../javascript/utils/uploader';

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

    const MdEditor = Markdown(Editor);
    this.editor = new MdEditor({
      element: this.editorTarget,
      content,
      autofocus: true,
      markdown: {
        breaks: false,
      },
      extensions: [
        BubbleMenu.configure({
          tippyOptions: {
            theme: 'light-border',
            arrow: false,
            placement: 'top-start',
          },
          element: this.bubbleMenuTarget,
        }),
        CodeBlockLowlight.configure({
          lowlight,
        }),
        FloatingMenu.configure({
          element: this.floatingMenuTarget,
          tippyOptions: {
            theme: 'light-border',
            arrow: false,
            placement: 'bottom-start',
          },
        }),
        Highlight,
        Image.configure({ inline: false }),
        Link.configure({
          openOnClick: false,
        }),
        MarkdownPaste,
        Placeholder.configure({ placeholder: textarea.placeholder }),
        StarterKit.configure({
          codeBlock: false,
        }),
        Typography,
        Underline,
      ],
      editorProps: {
        attributes: {
          class: 'prose-article focus:outline-none',
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
    if (this.editor.isActive('image') || this.editor.isActive('codeBlock')) {
      this.bubbleMenuTarget.classList.add('hidden');
    } else {
      this.bubbleMenuTarget.classList.remove('hidden');
    }

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
        button.classList.add('bg-[#F4F4F4]', 'dark:bg-[#333444]');
      } else {
        button.classList.remove('bg-[#F4F4F4]', 'dark:bg-[#333444]');
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

  addBlockquote(event) {
    event.preventDefault();
    this.editor.chain().focus().toggleBlockquote().run();
  }

  addCodeBlock(event) {
    event.preventDefault();
    this.editor.chain().focus().toggleCodeBlock().run();
  }
}

const MarkdownPaste = Extension.create({
  name: 'markdown-paste',

  addProseMirrorPlugins() {
    const { editor } = this;

    return [
      new Plugin({
        key: new PluginKey('markdown-paste'),
        props: {
          handlePaste(view, event) {
            if (view.props.editable && !view.props.editable(view.state)) {
              return false;
            }
            if (!event.clipboardData) return false;

            const text = event.clipboardData.getData('text/plain');
            const html = event.clipboardData.getData('text/html');
            if (text.length === 0 || html.length !== 0) return false;

            if (editor.getText()) {
              editor.commands.insertContentAt(view.state.selection, text, { updateSelection: true });
            } else {
              editor.commands.setContent(text, true);
            }

            return true;
          },
        },
      }),
    ];
  },
});
