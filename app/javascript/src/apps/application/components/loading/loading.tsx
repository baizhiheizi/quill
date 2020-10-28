import { Spin } from 'antd';
import React from 'react';

export function Loading() {
  return (
    <div style={{ width: '100%', padding: '2rem', textAlign: 'center' }}>
      <Spin />
    </div>
  );
}
