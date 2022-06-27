# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin '@rails/request.js', to: 'https://ga.jspm.io/npm:@rails/request.js@0.0.6/src/index.js', preload: true
pin '@rails/activestorage', to: 'https://ga.jspm.io/npm:@rails/activestorage@7.0.3/app/assets/javascripts/activestorage.esm.js', preload: true
pin '@rails/actioncable', to: 'https://ga.jspm.io/npm:@rails/actioncable@6.0.5/app/assets/javascripts/action_cable.js', preload: true

pin 'stimulus-use', to: 'https://ga.jspm.io/npm:stimulus-use@0.50.0/dist/index.js'
pin 'hotkeys-js', to: 'https://ga.jspm.io/npm:hotkeys-js@3.9.4/dist/hotkeys.esm.js'

pin 'flatpickr', to: 'https://ga.jspm.io/npm:flatpickr@4.6.13/dist/esm/index.js'
pin 'stimulus-flatpickr', to: 'https://ga.jspm.io/npm:stimulus-flatpickr@3.0.0-0/dist/index.m.js'

pin 'photoswipe', to: 'https://unpkg.com/photoswipe/dist/photoswipe.esm.js'
pin 'photoswipe-lightbox', to: 'https://unpkg.com/photoswipe/dist/photoswipe-lightbox.esm.js'

pin 'easymde', to: 'https://unpkg.com/easymde/dist/easymde.min.js'

pin 'lodash/debounce', to: 'https://ga.jspm.io/npm:lodash@4.17.21/debounce.js'
pin 'mixin-messenger-utils', to: 'https://ga.jspm.io/npm:mixin-messenger-utils@0.1.5/dist/index.js'
pin 'buffer', to: 'https://ga.jspm.io/npm:@jspm/core@2.0.0-beta.24/nodelibs/browser/buffer.js'
pin 'copy-to-clipboard', to: 'https://ga.jspm.io/npm:copy-to-clipboard@3.3.1/index.js'
pin 'js-base64', to: 'https://ga.jspm.io/npm:js-base64@3.7.2/base64.js'
pin 'toggle-selection', to: 'https://ga.jspm.io/npm:toggle-selection@1.0.6/index.js'
pin 'highlight.js', to: 'https://ga.jspm.io/npm:highlight.js@11.5.1/es/index.js'

pin 'qrcode', to: 'https://unpkg.com/qrcode@1.5.0/build/qrcode.js'

pin 'tom-select', to: 'https://ga.jspm.io/npm:tom-select@2.0.3/dist/js/tom-select.complete.js'
pin 'abortcontroller-polyfill', to: 'https://ga.jspm.io/npm:abortcontroller-polyfill@1.7.3/dist/umd-polyfill.js'

pin '@metamask/detect-provider', to: 'https://ga.jspm.io/npm:@metamask/detect-provider@1.2.0/dist/index.js'
pin 'web3', to: 'https://unpkg.com/web3@latest/dist/web3.min.js'

pin_all_from 'app/javascript/controllers', under: 'controllers'
pin_all_from 'app/javascript/utils', under: 'utils'
pin 'application'
