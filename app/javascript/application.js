// Entry point for the build script in your package.json
import 'abortcontroller-polyfill';
import '@hotwired/turbo-rails';
import { hideLoading, showLoading } from 'utils';
import 'controllers';

import * as ActiveStorage from '@rails/activestorage';
ActiveStorage.start();

addEventListener('turbo:submit-start', ({ target }) => {
  for (const field of target.elements) {
    field.disabled = true;
  }
  showLoading();
});

addEventListener('turbo:submit-end', () => {
  hideLoading();
});

addEventListener('turbo:click', () => {
  showLoading();
});

addEventListener('turbo:before-render', () => {
  hideLoading();
});

addEventListener('turbo:frame-render', () => {
  hideLoading();
});
