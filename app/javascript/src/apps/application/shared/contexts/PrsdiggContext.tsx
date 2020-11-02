import React, { useContext } from 'react';

export const PrsdiggContext = React.createContext(null);
export function usePrsdigg() {
  return useContext(PrsdiggContext);
}
