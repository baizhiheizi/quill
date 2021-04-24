import { message } from 'antd';
import { upload } from 'apps/shared';
import React from 'react';

export default function UploadComponent(props: {
  callback: (params: any) => any;
}) {
  return (
    <input
      className='hidden'
      id='upload-image-input'
      type='file'
      accept='image/*'
      multiple
      onChange={(event) => {
        Array.from(event.target.files).forEach((file) => {
          message.loading('...');
          upload(file, (blob) => {
            props.callback(blob);
            message.destroy();
          });
        });
      }}
    />
  );
}
