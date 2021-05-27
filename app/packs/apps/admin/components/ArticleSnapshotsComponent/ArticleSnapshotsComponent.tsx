import { useDebounce } from 'ahooks';
import { Button, Input, Popconfirm, Popover, Select, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import {
  ArticleSnapshot,
  useAdminArticleSnapshotConnectionQuery,
  useAdminSignArticleSnapshotMutation,
} from 'graphqlTypes';
import React, { useState } from 'react';
import { Link } from 'react-router-dom';

export default function ArticleSnapshotsComponent(props: {
  articleUuid?: string;
}) {
  const { articleUuid } = props;
  const [state, setState] = useState('all');
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, { wait: 500 });
  const { loading, data, fetchMore, refetch } =
    useAdminArticleSnapshotConnectionQuery({
      variables: { articleUuid, state, query: debouncedQuery },
    });
  const [signArticleSnapshot, { loading: signing }] =
    useAdminSignArticleSnapshotMutation();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminArticleSnapshotConnection: {
      nodes: snapshots,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;
  const columns: Array<ColumnProps<ArticleSnapshot>> = [
    {
      dataIndex: 'id',
      key: 'id',
      title: 'ID',
    },
    {
      dataIndex: 'article',
      key: 'article',
      render: (_, snapshot) => (
        <span>
          {snapshot.article.author.name}:{' '}
          <Link to={`/articles/${snapshot.articleUuid}`}>
            {snapshot.article.title}
          </Link>
        </span>
      ),
      title: 'Article',
    },
    {
      dataIndex: 'state',
      key: 'state',
      title: 'State',
    },
    {
      dataIndex: 'fileHash',
      key: 'fileHash',
      render: (text) =>
        text ? (
          <Popover content={text} className='w-14 line-clamp-1'>
            {text}
          </Popover>
        ) : (
          '-'
        ),
      title: 'File Hash',
    },
    {
      dataIndex: 'txId',
      key: 'txId',
      render: (text) =>
        text ? (
          <Popover content={text} className='w-14 line-clamp-1'>
            {text}
          </Popover>
        ) : (
          '-'
        ),
      title: 'Tx ID',
    },
    {
      dataIndex: 'signature',
      key: 'signature',
      render: (_, snapshot) =>
        snapshot?.signatureUrl ? (
          <a href={snapshot.signatureUrl} target='_blank'>
            Link
          </a>
        ) : (
          '-'
        ),
      title: 'signature',
    },
    {
      dataIndex: 'requestedAt',
      key: 'requestedAt',
      render: (text) => text || '-',
      title: 'requestedAt',
    },
    {
      dataIndex: 'signedAt',
      key: 'signedAt',
      render: (text) => text || '-',
      title: 'signedAt',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'CreatedAt',
    },
    {
      dataIndex: 'actions',
      key: 'actions',
      render: (_, snapshot) => (
        <Popconfirm
          title='Are you sure to sign this snapshot?'
          disabled={snapshot.state !== 'drafted' || signing}
          onConfirm={() =>
            signArticleSnapshot({ variables: { input: { id: snapshot.id } } })
          }
        >
          <span
            className={
              snapshot.state === 'drafted' || signing
                ? 'cursor-pointer'
                : 'cursor-not-allowed text-gray-500'
            }
          >
            Sign
          </span>
        </Popconfirm>
      ),
      title: 'Actions',
    },
  ];

  return (
    <>
      <div className='flex justify-between mb-4'>
        <div className='flex space-x-4'>
          <Select
            className='w-48'
            value={state}
            onChange={(value) => setState(value)}
          >
            <Select.Option value='all'>All</Select.Option>
            <Select.Option value='drafted'>Drafted</Select.Option>
            <Select.Option value='signing'>Signing</Select.Option>
            <Select.Option value='signed'>Signed</Select.Option>
          </Select>
          <Input
            className='w-72'
            value={query}
            placeholder='title/content/author/hash/txId'
            onChange={(e) => setQuery(e.currentTarget.value)}
          />
        </div>
        <Button type='primary' onClick={() => refetch()}>
          Refresh
        </Button>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={snapshots}
        size='small'
        rowKey='id'
        pagination={false}
      />
      <div className='mb-4 text-center'>
        <Button
          type='link'
          loading={loading}
          disabled={!hasNextPage}
          onClick={() => {
            fetchMore({
              variables: {
                after: endCursor,
              },
            });
          }}
        >
          {hasNextPage ? 'Load More' : 'No More'}
        </Button>
      </div>
    </>
  );
}
