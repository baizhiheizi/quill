import { Controller } from '@hotwired/stimulus';
import { mixinContext } from 'mixin-messenger-utils';
import PhotoSwipeLightbox from 'photoswipe/dist/photoswipe-lightbox.esm';
import PhotoSwipe from 'photoswipe/dist/photoswipe.esm.js';

export default class extends Controller {
  connect() {
    this.wrapImgs();
    this.initLightbox();
  }

  initLightbox() {
    this.lightbox = new PhotoSwipeLightbox({
      gallerySelector: '.photoswipe-gallery',
      childSelector: 'a.photoswipe',
      pswpModule: PhotoSwipe,
      mainClass: mixinContext?.immersive ? 'immersive' : '',
    });
    this.lightbox.init();
  }

  wrapImgs() {
    this.element.querySelectorAll('img').forEach((img) => {
      img.onload = (e) => {
        e.target.parentElement.setAttribute(
          'data-pswp-width',
          e.target.naturalWidth,
        );
        e.target.parentElement.setAttribute(
          'data-pswp-height',
          e.target.naturalHeight,
        );
      };
    });
  }
}