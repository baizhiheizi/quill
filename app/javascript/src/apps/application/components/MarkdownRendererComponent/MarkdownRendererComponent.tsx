import MDEditor from '@uiw/react-md-editor';
import React from 'react';
import Zoom from 'react-medium-image-zoom';
import './MarkdownRendererComponent.less';

export default function MarkdownRendererComponent(props: { source: string }) {
  return (
    <MDEditor.Markdown
      source={props.source}
      renderers={{
        image: ({ src, alt }) => (
          <Zoom wrapElement='span'>
            <img src={src} alt={alt} />
          </Zoom>
        ),
      }}
    />
  );
}
