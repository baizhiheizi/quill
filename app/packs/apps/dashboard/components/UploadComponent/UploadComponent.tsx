import { message } from 'antd';
import { upload, usePrsdigg } from 'apps/shared';
import React from 'react';

export default function UploadComponent(props: {
  callback: (params: any) => any;
}) {
  const { attachmentEndpoint } = usePrsdigg();
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
            blob.url = `${attachmentEndpoint}/${blob.key}`;
            props.callback(blob);
            message.destroy();
          });
        });
      }}
    />
  );
}
