require('@rails/ujs').start();
require('@rails/activestorage').start();
require('channels');

var componentRequireContext = require.context('src/apps/admin', true);
var ReactRailsUJS = require('react_ujs');
ReactRailsUJS.useContext(componentRequireContext);
