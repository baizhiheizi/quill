import { Controller } from '@hotwired/stimulus';
import { mixinContext } from 'mixin-messenger-utils';
import PhotoSwipe from 'photoswipe';
import PhotoSwipeLightbox from 'photoswipe-lightbox';

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
      mainClass: mixinContext && mixinContext.immersive ? 'immersive' : '',
    });
    this.lightbox.init();
  }

  wrapImgs() {
    this.element.querySelectorAll('img').forEach((img) => {
      img.parentElement.setAttribute('data-pswp-width', img.naturalWidth);
      img.parentElement.setAttribute('data-pswp-height', img.naturalHeight);

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
