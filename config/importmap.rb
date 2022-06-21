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

pin 'codemirror', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/lib/codemirror.js'
pin 'codemirror-spell-checker', to: 'https://ga.jspm.io/npm:codemirror-spell-checker@1.1.2/src/js/spell-checker.js'
pin 'codemirror/addon/display/autorefresh.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/addon/display/autorefresh.js'
pin 'codemirror/addon/display/fullscreen.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/addon/display/fullscreen.js'
pin 'codemirror/addon/display/placeholder.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/addon/display/placeholder.js'
pin 'codemirror/addon/edit/continuelist.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/addon/edit/continuelist.js'
pin 'codemirror/addon/mode/overlay.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/addon/mode/overlay.js'
pin 'codemirror/addon/search/searchcursor.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/addon/search/searchcursor.js'
pin 'codemirror/addon/selection/mark-selection.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/addon/selection/mark-selection.js'
pin 'codemirror/mode/gfm/gfm.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/mode/gfm/gfm.js'
pin 'codemirror/mode/markdown/markdown.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/mode/markdown/markdown.js'
pin 'codemirror/mode/xml/xml.js', to: 'https://ga.jspm.io/npm:codemirror@5.65.5/mode/xml/xml.js'
pin 'fs', to: 'https://ga.jspm.io/npm:@jspm/core@2.0.0-beta.24/nodelibs/browser/fs.js'
pin 'marked', to: 'https://ga.jspm.io/npm:marked@4.0.16/lib/marked.cjs'
pin 'typo-js', to: 'https://ga.jspm.io/npm:typo-js@1.2.1/typo.js'
pin 'easymde', to: 'https://ga.jspm.io/npm:easymde@2.16.1/src/js/easymde.js'

pin 'lodash', to: 'https://ga.jspm.io/npm:lodash@4.17.21/lodash.js'
pin 'mixin-messenger-utils', to: 'https://ga.jspm.io/npm:mixin-messenger-utils@0.1.5/dist/index.js'
pin 'buffer', to: 'https://ga.jspm.io/npm:@jspm/core@2.0.0-beta.24/nodelibs/browser/buffer.js'
pin 'copy-to-clipboard', to: 'https://ga.jspm.io/npm:copy-to-clipboard@3.3.1/index.js'
pin 'js-base64', to: 'https://ga.jspm.io/npm:js-base64@3.7.2/base64.js'
pin 'toggle-selection', to: 'https://ga.jspm.io/npm:toggle-selection@1.0.6/index.js'
pin 'highlight.js', to: 'https://ga.jspm.io/npm:highlight.js@11.5.1/es/index.js'
pin 'qrcode', to: 'https://ga.jspm.io/npm:qrcode@1.5.0/lib/browser.js'
pin 'dijkstrajs', to: 'https://ga.jspm.io/npm:dijkstrajs@1.0.2/dijkstra.js'
pin 'encode-utf8', to: 'https://ga.jspm.io/npm:encode-utf8@2.0.0/index.js'
pin 'tom-select', to: 'https://ga.jspm.io/npm:tom-select@2.0.3/dist/js/tom-select.complete.js'
pin 'abortcontroller-polyfill', to: 'https://ga.jspm.io/npm:abortcontroller-polyfill@1.7.3/dist/umd-polyfill.js'

pin_all_from 'app/javascript/controllers', under: 'controllers'
pin_all_from 'app/javascript/utils', under: 'utils'
pin 'application'
