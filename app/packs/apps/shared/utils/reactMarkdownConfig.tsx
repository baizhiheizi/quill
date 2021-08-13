import { FileImageOutlined } from '@ant-design/icons';
import { ICommand, TextAreaTextApi, TextState } from '@uiw/react-md-editor';
import { message } from 'antd';
import { upload } from 'apps/shared';
import katex from 'katex';
import 'katex/dist/katex.css';
import mermaid from 'mermaid';
import React from 'react';
import footnotes from 'remark-footnotes';
import { ATTACHMENT_ENDPOINT } from '../constants';

export const markdownPlugins: any = [[footnotes, { inlineNotes: true }]];
export const markdownTransformLinkUrl = (uri: string) => {
  // https://github.com/remarkjs/react-markdown/blob/main/src/uri-transformer.js
  // add the 'mixin://' scheme
  const protocols = ['http', 'https', 'mailto', 'tel', 'mixin'];
  const url = (uri || '').trim();
  const first = url.charAt(0);

  if (first === '#' || first === '/') {
    return url;
  }

  const colon = url.indexOf(':');
  if (colon === -1) {
    return url;
  }

  const length = protocols.length;
  let index = -1;

  while (++index < length) {
    const protocol = protocols[index];

    if (
      colon === protocol.length &&
      url.slice(0, protocol.length).toLowerCase() === protocol
    ) {
      return url;
    }
  }

  index = url.indexOf('?');
  if (index !== -1 && colon > index) {
    return url;
  }

  index = url.indexOf('#');
  if (index !== -1 && colon > index) {
    return url;
  }

  return 'javascript:void(0)';
};
export const markdownRenderers: any = {
  img: ({ src, alt }) => (
    <a className='photoswipe' data-pswp-src={src} target='_blank'>
      <img
        data-pswp-src={src}
        onLoad={(e: any) => {
          e.target.parentElement.setAttribute(
            'data-pswp-width',
            e.target.naturalWidth,
          );
          e.target.parentElement.setAttribute(
            'data-pswp-height',
            e.target.naturalHeight,
          );
        }}
        alt={alt}
        className='w-full'
        src={`${src}?x-oss-process=image/resize,w_768`}
      />
    </a>
  ),
  paragraph: ({ node, ...otherProps }) => (
    <div className='mb-4'>{otherProps.children}</div>
  ),
  footnote: ({ children }) => {
    return <sup className='italic'>{children}</sup>;
  },
  footnoteReference: ({ label, identifier }) => {
    return (
      <sup id={'ref-' + identifier}>
        <a href={'#def-' + identifier}>{label}</a>
      </sup>
    );
  },
  footnoteDefinition: ({ identifier, label, children }) => {
    return (
      <div className='flex' id={'def-' + identifier}>
        <a className='mr-2' href={'#ref-' + identifier}>
          {label}:
        </a>
        <span className='italic'>{children}</span>
      </div>
    );
  },
  code: ({ inline, children, className, ...props }) => {
    const txt = children[0] || '';
    // katex
    if (inline) {
      if (typeof txt === 'string' && /^\$\$(.*)\$\$/.test(txt)) {
        const html = katex.renderToString(txt.replace(/^\$\$(.*)\$\$/, '$1'), {
          throwOnError: false,
        });
        return <code dangerouslySetInnerHTML={{ __html: html }} />;
      }
      return <code>{children}</code>;
    }
    if (
      typeof txt === 'string' &&
      typeof className === 'string' &&
      /^language-katex/.test(className.toLocaleLowerCase())
    ) {
      const html = katex.renderToString(txt, {
        throwOnError: false,
      });
      return <code dangerouslySetInnerHTML={{ __html: html }} />;
    }

    // mermaid
    if (
      typeof txt === 'string' &&
      typeof className === 'string' &&
      /^language-mermaid/.test(className.toLocaleLowerCase())
    ) {
      const Elm = document.createElement('div');
      Elm.id = 'demo';
      const svg = mermaid.render('demo', txt);
      return <code dangerouslySetInnerHTML={{ __html: svg }} />;
    }
    return <code className={String(className)}>{children}</code>;
  },
};

export const markdownPreviewOptions = {
  transformLinkUri: markdownTransformLinkUrl,
  remarkPlugins: markdownPlugins,
  components: markdownRenderers,
  disallowedElements: ['script'],
  allowElement: (element, index, parent) => {
    if (element.tagName === 'iframe') {
      return (
        Boolean(element.properties.src) &&
        Boolean(
          element.properties.src
            .toString()
            .match(/^https:\/\/www\.(youtube|google)\.com/),
        )
      );
    } else {
      return true;
    }
  },
};

export const uploadCommand: ICommand = {
  name: 'upload',
  keyCommand: 'upload',
  buttonProps: { 'aria-label': 'Upload Image' },
  icon: <FileImageOutlined />,
  execute: (state: TextState, api: TextAreaTextApi) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.multiple = true;
    input.onchange = (event: any) => {
      Array.from(event.target.files).forEach((file) => {
        message.loading('...');
        upload(file, (blob) => {
          blob.url = `${ATTACHMENT_ENDPOINT}/${blob.key}`;
          api.replaceSelection(
            `${state.selectedText}\n![${blob.filename}](${blob.url})\n\n`,
          );
          message.destroy();
        });
      });
    };
    input.click();
  },
};
