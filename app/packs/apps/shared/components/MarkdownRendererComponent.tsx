import MDEditor from '@uiw/react-md-editor';
import React, { useEffect } from 'react';
import { usePhotoSwipe } from '../contexts';
import { markdownPreviewOptions } from '../utils';

export function MarkdownRendererComponent(props: { source: string }) {
  const { lightbox } = usePhotoSwipe();

  useEffect(() => {
    lightbox.init();
  });

  return (
    <MDEditor.Markdown
      className='photoswipe-gallery'
      source={props.source}
      {...markdownPreviewOptions}
    />
  );
}
