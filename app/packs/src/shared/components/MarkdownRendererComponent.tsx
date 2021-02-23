import MDEditor from '@uiw/react-md-editor';
import { Image } from 'antd';
import React from 'react';

export function MarkdownRendererComponent(props: { source: string }) {
  return (
    <MDEditor.Markdown
      source={props.source}
      transformLinkUri={(uri: string) => {
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
      }}
      renderers={{
        image: ({ src, alt }) => (
          <Image
            wrapperClassName='w-full'
            className='w-auto max-w-full m-auto'
            preview={false}
            alt={alt}
            src={src}
          />
        ),
        paragraph: ({ node, ...otherProps }) => (
          <div className='mb-4'>{otherProps.children}</div>
        ),
      }}
    />
  );
}
