import React, { useContext } from 'react';

export const PhotoSwipeContext = React.createContext(null);
export function usePhotoSwipe() {
  return useContext(PhotoSwipeContext);
}
