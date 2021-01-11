import MDEditor from '@uiw/react-md-editor';
import React from 'react';
import Zoom from 'react-medium-image-zoom';
import './MarkdownRendererComponent.less';

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
          <Zoom wrapElement='span'>
            <img style={{ maxWidth: '100%' }} src={src} alt={alt} />
          </Zoom>
        ),
      }}
    />
  );
}
