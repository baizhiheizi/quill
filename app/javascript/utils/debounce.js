// Trailing-edge debounce with a `cancel` handle — the only pieces of
// underscore this bundle ever used.
export function debounce(fn, wait = 0) {
  let timer;
  const debounced = (...args) => {
    debounced.cancel();
    timer = setTimeout(() => {
      timer = undefined;
      fn(...args);
    }, wait);
  };
  debounced.cancel = () => {
    clearTimeout(timer);
    timer = undefined;
  };
  return debounced;
}
