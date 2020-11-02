import { Spin } from 'antd';
import React from 'react';

export default function LoadingComponent() {
  return (
    <div style={{ width: '100%', padding: '2rem', textAlign: 'center' }}>
      <Spin />
    </div>
  );
}
