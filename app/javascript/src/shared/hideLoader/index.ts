export function hideLoader() {
  const ele: any = document.querySelector('.loader-wrapper');
  if (Boolean(ele)) {
    ele.style.display = 'none';
  }
}
