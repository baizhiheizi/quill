import MDEditor from '@uiw/react-md-editor';
import React from 'react';
import { markdownPreviewOptions } from '../utils';

export function MarkdownRendererComponent(props: { source: string }) {
  return (
    <MDEditor.Markdown source={props.source} {...markdownPreviewOptions} />
  );
}
