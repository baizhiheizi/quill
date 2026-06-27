62
Mobile floating action bar. showDelay (150) hideDelay (500) values. connect: debounce(show.bind(this), showDelay); boundOnScroll() calls show + clearTimeout(hideTimer) + setTimeout(hide, hideDelay). removeEventListener + clearTimeout in disconnect. passive scroll listener. show()/hide() toggle translate-y-24 class. Debounce the function, not its return value.
