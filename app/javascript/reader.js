// Article-reader entry: PhotoSwipe, highlight.js, and QR codes. Loaded on
// every page except the guest desktop landing so first paint stays lean.
import { application } from "./controllers/application";

import PhotoswipeController from "./controllers/photoswipe_controller";
application.register("photoswipe", PhotoswipeController);

import HljsController from "./controllers/hljs_controller";
application.register("hljs", HljsController);

import SyntaxHighlightController from "./controllers/syntax_highlight_controller";
application.register("syntax-highlight", SyntaxHighlightController);

import QrcodeComponentController from "./controllers/qrcode_component_controller";
application.register("qrcode-component", QrcodeComponentController);
