import { Application } from '@hotwired/stimulus';

if (!window.Stimulus) {
  const application = Application.start();
  window.Stimulus = application;
}

const application = window.Stimulus;
export { application };
