// specs/011-comprehensive-ui-refactor — T049.
//
// Toast template uses design-system icon utilities (i-[tabler--*]) instead
// of hand-rolled SVG strings. See contracts/primitives.md#notification-card.
//
// Color tokens per type come from Tailwind utilities (text-info, bg-info/10,
// etc.); the four notification kinds use semantic colors that already exist
// in the FlyonUI theme layer.

const ICON = {
  info: "i-[tabler--info-circle]",
  danger: "i-[tabler--alert-circle]",
  success: "i-[tabler--circle-check]",
  warning: "i-[tabler--alert-triangle]",
};

const TYPE_CLASS = {
  info: "text-info bg-info/10",
  danger: "text-error bg-error/10",
  success: "text-success bg-success/10",
  warning: "text-warning bg-warning/10",
};

const notificationTpl = (type, message) => {
  const icon = ICON[type] || ICON.info;
  const colorClass = TYPE_CLASS[type] || TYPE_CLASS.info;

  return `<div class="flex items-start gap-3 rounded-[10px] border border-base-300 ${colorClass} p-4" role="alert">
    <span class="${icon} mt-0.5 text-lg leading-none" aria-hidden="true"></span>
    <div class="flex-1 text-sm font-medium">
      ${message}
    </div>
    <button type="button"
            class="-mx-1.5 -my-1.5 rounded-lg p-1.5 hover:bg-base-200 inline-flex h-8 w-8 focus-ring"
            data-action="notification#hide"
            aria-label="Close">
      <span class="sr-only">Close</span>
      <span class="i-[tabler--x] text-base-content" aria-hidden="true"></span>
    </button>
  </div>`;
};

export const notify = (message, type = "info") => {
  const slot = document.querySelector("#flashes");

  slot.innerHTML = `
<div
  data-controller="flash"
  data-notification-delay-value="3000"
  data-transition-enter-from="opacity-0 translate-x-6"
  data-transition-enter-to="opacity-100 translate-x-0"
  data-transition-leave-from="opacity-100 translate-x-0"
  data-transition-leave-to="opacity-0 translate-x-6"
  class="hidden transition relative transform duration-1000 flex justify-end max-w-xl ml-auto"
>
  ${notificationTpl(type, message)}
</div>
  `;
};
