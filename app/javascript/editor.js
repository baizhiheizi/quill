// Editor-only entry: Lexxy + Action Text custom elements, plus Tom Select
// controllers used on the article form. Loaded from the editor layout so
// the public landing bundle does not pay for the rich-text editor.
import "@rails/actiontext";
import "@37signals/lexxy";

import { application } from "./controllers/application";
import TagsSelectController from "./controllers/tags_select_controller";
import ReferencesSelectController from "./controllers/references_select_controller";

application.register("tags-select", TagsSelectController);
application.register("references-select", ReferencesSelectController);
