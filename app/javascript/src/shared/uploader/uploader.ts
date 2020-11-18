export const DIRECT_UPLOAD_URL = '/rails/active_storage/direct_uploads';
export const DIRECT_UPLOAD_END_POINT =
  'https://prsdigg.oss-cn-hongkong.aliyuncs.com/';

import { DirectUpload } from '@rails/activestorage';

export function upload(file: any, callback: (params: any) => any) {
  const uploader = new DirectUpload(file, DIRECT_UPLOAD_URL);
  uploader.create((error, blob) => {
    if (error) {
      console.error(error.toString());
    } else {
      return callback(DIRECT_UPLOAD_END_POINT + blob.key);
    }
  });
}
