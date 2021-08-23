export const FOXSWAP_APP_ID = 'a753e0eb-3010-4c4a-a7b2-a7bda4063f62';
export const FOXSWAP_CODE_ID = '2140515d-b77f-4476-92f6-39d953c74cc5';
export const ATTACHMENT_ENDPOINT = () => {
  try {
    const context = JSON.parse(
      document.getElementsByClassName('js-react-on-rails-component')[0]
        .innerHTML,
    );
    return context.prsdigg.attachmentEndpoint;
  } catch (error) {
    console.error(error);
    if (location.origin.includes('bunshow')) {
      return 'https://bunshow.oss-accelerate.aliyuncs.com';
    } else {
      return 'https://prsdigg.oss-accelerate.aliyuncs.com';
    }
  }
};
