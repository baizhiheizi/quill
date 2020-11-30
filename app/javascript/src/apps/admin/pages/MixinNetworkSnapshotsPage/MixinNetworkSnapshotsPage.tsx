import MixinNetworkSnapshotsComponent from '@admin/components/MixinNetworkSnapshotsComponent/MixinNetworkSnapshotComponent';
import { Col, PageHeader, Row, Select } from 'antd';
import React, { useState } from 'react';

export default function MixinNetworkSnapshotsPage() {
  const [filter, setFilter] = useState<'input' | 'output' | 'prsdigg' | 'all'>(
    'input',
  );
  return (
    <div>
      <PageHeader title='Mixin Network Snapshot' />
      <Row gutter={16} style={{ marginBottom: '1rem' }}>
        <Col>
          <Select
            style={{ width: 200 }}
            value={filter}
            onChange={(value) => setFilter(value)}
          >
            <Select.Option value='input'>Input</Select.Option>
            <Select.Option value='output'>Output</Select.Option>
            <Select.Option value='prsdigg'>PRSDigg</Select.Option>
            <Select.Option value='4swap'>4swap</Select.Option>
            <Select.Option value='all'>All</Select.Option>
          </Select>
        </Col>
      </Row>
      <MixinNetworkSnapshotsComponent filter={filter} />
    </div>
  );
}
