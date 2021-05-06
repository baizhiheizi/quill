import { Button, Table } from 'antd';
import { ColumnProps } from 'antd/es/table';
import LoadingComponent from 'apps/admin/components/LoadingComponent/LoadingComponent';
import {
  ArticleSnapshot,
  useAdminArticleSnapshotConnectionQuery,
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
      dataIndex: 'fileHash',
      key: 'fileHash',
      title: 'File Hash',
    },
    {
      dataIndex: 'txId',
      key: 'txId',
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
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'CreatedAt',
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
