import { PageHeader } from 'antd';
import MixinNetworkSnapshotsComponent from 'apps/admin/components/MixinNetworkSnapshotsComponent/MixinNetworkSnapshotComponent';
import React from 'react';

export default function MixinNetworkSnapshotsPage() {
  return (
    <>
      <PageHeader title='Mixin Network Snapshot' />
      <MixinNetworkSnapshotsComponent />
    </>
  );
}
