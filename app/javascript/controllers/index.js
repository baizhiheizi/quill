// Core Stimulus controllers for every page. PhotoSwipe, highlight.js,
// QR codes, and Tom Select are registered from reader.js / editor.js so
// the landing bundle stays lean. Re-running stimulus:manifest:update will
// put those imports back — move them out again.

import { application } from "./application";

import ArticleFormController from "./article_form_controller";
application.register("article-form", ArticleFormController);

import ArticleRevenueController from "./article_revenue_controller";
application.register("article-revenue", ArticleRevenueController);

import AvatarController from "./avatar_controller";
application.register("avatar", AvatarController);

import AutoHideController from "./auto_hide_controller";
application.register("auto-hide", AutoHideController);

import ClipboardController from "./clipboard_controller";
application.register("clipboard", ClipboardController);

import CollectionsFormComponentController from "./collections_form_component_controller";
application.register(
  "collections-form-component",
  CollectionsFormComponentController,
);

import CommentFormController from "./comment_form_controller";
application.register("comment-form", CommentFormController);

import DarkmodeController from "./darkmode_controller";
application.register("darkmode", DarkmodeController);

import FlyonuiDropdownController from "./flyonui_dropdown_controller";
application.register("flyonui-dropdown", FlyonuiDropdownController);

import DropdownController from "./dropdown_controller";
application.register("dropdown", DropdownController);

import FlashController from "./flash_controller";
application.register("flash", FlashController);

import FloatingController from "./floating_controller";
application.register("floating", FloatingController);

import InfiniteScrollController from "./infinite_scroll_controller";
application.register("infinite-scroll", InfiniteScrollController);

import LoadMoreController from "./load_more_controller";
application.register("load-more", LoadMoreController);

import MastheadController from "./masthead_controller";
application.register("masthead", MastheadController);

import FlyonuiModalController from "./flyonui_modal_controller";
application.register("modal-component", FlyonuiModalController);

import NestedFormController from "./nested_form_controller";
application.register("nested-form", NestedFormController);

import PreOrdersFormComponentController from "./pre_orders_form_component_controller";
application.register(
  "pre-orders-form-component",
  PreOrdersFormComponentController,
);

import PreOrdersPayButtonComponentController from "./pre_orders_pay_button_component_controller";
application.register(
  "pre-orders-pay-button-component",
  PreOrdersPayButtonComponentController,
);

import PreOrdersPaymentComponentController from "./pre_orders_payment_component_controller";
application.register(
  "pre-orders-payment-component",
  PreOrdersPaymentComponentController,
);

import PreOrdersStateComponentController from "./pre_orders_state_component_controller";
application.register(
  "pre-orders-state-component",
  PreOrdersStateComponentController,
);

import PrefetchController from "./prefetch_controller";
application.register("prefetch", PrefetchController);

import PaywallFadeController from "./paywall_fade_controller";
application.register("paywall-fade", PaywallFadeController);

import PreviewUploadController from "./preview_upload_controller";
application.register("preview-upload", PreviewUploadController);

import PreviewController from "./preview_controller";
application.register("preview", PreviewController);

import SearchController from "./search_controller";
application.register("search", SearchController);

import SelectCurrencyController from "./select_currency_controller";
application.register("select-currency", SelectCurrencyController);

import SidebarController from "./sidebar_controller";
application.register("sidebar", SidebarController);

import TabsController from "./tabs_controller";
application.register("tabs", TabsController);

import TextareaController from "./textarea_controller";
application.register("textarea", TextareaController);

import TimeFormatComponentController from "./time_format_component_controller";
application.register("time-format-component", TimeFormatComponentController);

import TurboController from "./turbo_controller";
application.register("turbo", TurboController);
