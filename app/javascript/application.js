// Entry point for the build script in your package.json
import '@rails/actiontext';
import '@37signals/lexxy';

import '@hotwired/turbo-rails';
import { hideLoading } from './utils';
import './controllers';
import './polyfill';
import 'flyonui/flyonui';

const initFlyonUI = () => {
  window.HSStaticMethods?.autoInit();
};

import * as ActiveStorage from '@rails/activestorage';
ActiveStorage.start();

addEventListener('turbo:submit-start', ({ target }) => {
  if (target && target.elements) {
    for (const field of target.elements) {
      field.disabled = true;
    }
  }
});

const FetchMethod = { get: 0 };
addEventListener('turbo:submit-end', async ({ target, detail }) => {
  if (target && target.elements) {
    for (const field of target.elements) {
      field.disabled = false;
    }
  }
  hideLoading();

  const nonGetFetch =
    detail.formSubmission.fetchRequest.method !== FetchMethod.get;
  const responseHTML = await detail.fetchResponse.responseHTML;
  if (detail.success && nonGetFetch && responseHTML) {
    setTimeout(() => {
      Turbo.cache.clear();
    }, '1000');
  }
});

addEventListener('turbo:load', () => {
  hideLoading();
  initFlyonUI();
});

addEventListener('turbo:render', () => {
  hideLoading();
  initFlyonUI();
});

addEventListener('turbo:frame-render', () => {
  hideLoading();
  initFlyonUI();
});
