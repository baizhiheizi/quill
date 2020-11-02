import React, { useContext } from 'react';

export const MixinContext = React.createContext(null);
export function useMixin() {
  return useContext(MixinContext);
}
