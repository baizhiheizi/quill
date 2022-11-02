import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['input', 'output', 'imageTpl', 'videoTpl', 'audioTpl'];

  connect() {
    this.preview();
  }

  preview() {
    const input = this.inputTarget;

    if (input.files && input.files[0]) {
      const file = input.files[0];
      switch (file.type.split('/')[0]) {
        case 'video':
          if (this.hasVideoTplTarget) {
            const video = this.videoTplTarget;
            video.src = URL.createObjectURL(file);
            video.classList.remove('hidden');
            video.dataset['controller'] = 'player';
            video.setAttribute('controls', true);
            this.outputTarget.replaceChildren(video);
          } else {
            this.outputTarget.innerHTML = `<video class="w-full" data-controller="player" data-player-target="media" src=${URL.createObjectURL(
              file,
            )} controls></video>`;
          }
          break;
        case 'audio':
          if (this.hasAudioTplTarget) {
            const audio = this.audioTplTarget;
            audio.src = URL.createObjectURL(file);
            audio.classList.remove('hidden');
            audio.dataset['controller'] = 'player';
            audio.setAttribute('controls', true);
            this.outputTarget.replaceChildren(audio);
          } else {
            this.outputTarget.innerHTML = `<video class="w-full" data-controller="player" data-player-target="media" src=${URL.createObjectURL(
              file,
            )} controls></video>`;
          }
          break;
        case 'image':
          if (this.hasImageTplTarget) {
            const image = this.imageTplTarget;
            image.src = URL.createObjectURL(file);
            image.classList.remove('hidden');
            this.outputTarget.replaceChildren(image);
          } else {
            this.outputTarget.innerHTML = `<img class="w-full" src=${URL.createObjectURL(
              file,
            )} />`;
          }
          break;
      }
    }
  }
}
