import MDEditor from '@uiw/react-md-editor';
import React from 'react';
import Zoom from 'react-medium-image-zoom';
import './MarkdownRendererComponent.less';

export function MarkdownRendererComponent(props: { source: string }) {
  return (
    <MDEditor.Markdown
      source={props.source}
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
