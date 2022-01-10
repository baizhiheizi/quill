// Entry point for the build script in your package.json
import 'abortcontroller-polyfill/dist/polyfill-patch-fetch';
import '@hotwired/turbo-rails';
import './controllers';
