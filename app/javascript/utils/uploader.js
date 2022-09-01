import { DirectUpload } from '@rails/activestorage';

export class Uploader {
  constructor(url, token, name) {
    this.url = url;
    this.token = token;
    this.name = name;
  }

  upload(file) {
    const uploader = new DirectUpload(file, this.url, this.token, this.name);
    return new Promise((resolve) => {
      uploader.create((error, blob) => {
        if (error) {
          console.error(error);
          resolve({ error });
        } else {
          resolve(blob);
        }
      });
    });
  }
}
