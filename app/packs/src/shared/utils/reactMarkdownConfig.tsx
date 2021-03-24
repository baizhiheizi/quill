import { Image } from 'antd';
import React from 'react';
import footnotes from 'remark-footnotes';

export const markdownPlugins = [[footnotes, { inlineNotes: true }]];
export const markdownRenderers = {
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
};
