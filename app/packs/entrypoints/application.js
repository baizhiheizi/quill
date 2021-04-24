import ReactOnRails from 'react-on-rails';
import ApplicationApp from '../apps/application/App';
import '../stylesheets/application.css';

// This is how react_on_rails can see the HelloWorld in the browser.
ReactOnRails.register({
  ApplicationApp,
});
