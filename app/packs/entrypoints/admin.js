import ReactOnRails from 'react-on-rails';
import AdminApp from '../apps/admin/App';
import '../stylesheets/admin.css';

// This is how react_on_rails can see the HelloWorld in the browser.
ReactOnRails.register({
  AdminApp,
});
