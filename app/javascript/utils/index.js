export * from 'utils/abis';
export * from 'utils/register';
export * from 'utils/mvm';

export const showLoading = () => {
  document.querySelector('#loading-toast').classList.remove('hidden');
};

export const hideLoading = () => {
  document.querySelector('#loading-toast').classList.add('hidden');
};
