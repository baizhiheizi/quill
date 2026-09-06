import { Controller } from "@hotwired/stimulus";

// Formats the `datetime-value` in the viewer's local timezone. Plain `Date`
// arithmetic — the three fixed shapes below don't need a date library.
export default class extends Controller {
  static targets = ["time"];
  static values = {
    format: String,
    datetime: String,
  };

  datetimeValueChanged() {
    if (!this.datetimeValue) {
      return;
    }

    const datetime = new Date(this.datetimeValue);
    if (Number.isNaN(datetime.getTime())) {
      return;
    }

    const pad = (n) => String(n).padStart(2, "0");
    const date = `${pad(datetime.getMonth() + 1)}/${pad(datetime.getDate())}`;
    const time = `${pad(datetime.getHours())}:${pad(datetime.getMinutes())}`;

    if (this.formatValue === "date") {
      this.element.innerText = date;
    } else if (this.formatValue === "time") {
      this.element.innerText = time;
    } else {
      this.element.innerText = `${datetime.getFullYear()}-${pad(datetime.getMonth() + 1)}-${pad(datetime.getDate())} ${time}`;
    }
  }
}
