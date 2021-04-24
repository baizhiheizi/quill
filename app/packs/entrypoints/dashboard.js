import ReactOnRails from 'react-on-rails';
import DashboardApp from '../apps/dashboard/App';
import '../stylesheets/dashboard.css';

// This is how react_on_rails can see the HelloWorld in the browser.
ReactOnRails.register({
  DashboardApp,
});
