export const DIRECT_UPLOAD_URL = '/rails/active_storage/direct_uploads';

import { DirectUpload } from '@rails/activestorage';

export function upload(file: any, callback: (params: any) => any) {
  const uploader = new DirectUpload(file, DIRECT_UPLOAD_URL);
  uploader.create((error, blob) => {
    if (error) {
      console.error(error.toString());
    } else {
      return callback({
        key: blob.key,
        signedId: blob.signed_id,
        filename: blob.filename,
      });
    }
  });
}
