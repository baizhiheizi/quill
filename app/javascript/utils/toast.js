export const showLoading = () => {
  document.querySelector('#loading-toast').classList.remove('hidden');
};

export const hideLoading = () => {
  document.querySelector('#loading-toast').classList.add('hidden');
};
