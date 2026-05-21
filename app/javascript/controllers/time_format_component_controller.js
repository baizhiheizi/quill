import { Controller } from '@hotwired/stimulus';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';
import advancedFormat from 'dayjs/plugin/advancedFormat';
dayjs.extend(utc);
dayjs.extend(timezone);
dayjs.extend(advancedFormat);

export default class extends Controller {
  static targets = ['time'];
  static values = {
    format: String,
    datetime: String,
  };

  datetimeValueChanged() {
    if (!this.datetimeValue) {
      return;
    }

    let format = 'YYYY-MM-DD HH:mm';
    if (this.formatValue === 'date') {
      format = 'MM/DD';
    } else if (this.formatValue === 'time') {
      format = 'HH:mm';
    }

    this.element.innerText = dayjs(this.datetimeValue).format(format);
  }
}
