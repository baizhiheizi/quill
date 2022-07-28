import { Controller } from '@hotwired/stimulus';
import { post } from '@rails/request.js';

export default class extends Controller {
  static targets = ['lightButton', 'darkButton'];

  connect() {}

  switch(event) {
    event.preventDefault();

    const { locale } = event.params;
    post('/locales', {
      body: {
        locale,
      },
    }).then(() => {
      Turbo.visit(location.pathname);
    });
  }
}
