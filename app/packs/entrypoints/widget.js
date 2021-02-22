require('@rails/ujs').start();
require('@rails/activestorage').start();
require('turbolinks').start();
require('channels');

import 'stylesheets/widget.css';
import Mark from 'mark.js';

document.addEventListener('turbolinks:load', function () {
  const context = document.querySelector('.mark-context');
  const instance = new Mark(context);
  const keywords = JSON.parse(
    document.querySelector('.mark-keywords')?.dataset?.keywords,
  );
  instance.mark(keywords);
});
