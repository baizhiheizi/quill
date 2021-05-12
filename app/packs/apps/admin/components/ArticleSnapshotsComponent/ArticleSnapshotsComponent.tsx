import { Button, Popconfirm, Popover, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import {
  ArticleSnapshot,
  useAdminArticleSnapshotConnectionQuery,
  useAdminSignArticleSnapshotMutation,
} from 'graphqlTypes';
import React from 'react';
import { Link } from 'react-router-dom';

export default function ArticleSnapshotsComponent(props: {
  articleUuid?: string;
}) {
  const { articleUuid } = props;
  const { loading, data, fetchMore } = useAdminArticleSnapshotConnectionQuery({
    variables: { articleUuid },
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
    <div>
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
    </div>
  );
}
