require('@rails/ujs').start();
require('@rails/activestorage').start();
require('channels');

var componentRequireContext = require.context('src/apps/admin', true);
var ReactRailsUJS = require('react_ujs');
ReactRailsUJS.useContext(componentRequireContext);

import ReactOnRails from 'react-on-rails';
import AdminApp from '../apps/admin/App';
import '../stylesheets/admin.css';

// This is how react_on_rails can see the HelloWorld in the browser.
ReactOnRails.register({
  AdminApp,
});
