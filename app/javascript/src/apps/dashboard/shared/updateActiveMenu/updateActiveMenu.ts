import { useActiveMenu } from '@shared';
import { useEffect } from 'react';

export function updateActiveMenu(menuKey: string) {
  const { activeMenu, setActiveMenu } = useActiveMenu();
  useEffect(() => {
    if (activeMenu !== menuKey) {
      setActiveMenu(menuKey);
    }
  }, []);
}
