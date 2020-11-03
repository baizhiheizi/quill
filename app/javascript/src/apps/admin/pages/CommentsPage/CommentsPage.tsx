import {
  AdminCommentConnectionQueryHookResult,
  Comment as IComment,
  useAdminCommentConnectionQuery,
} from '@graphql';
import { Avatar, Button, PageHeader, Popconfirm, Popover, Space } from 'antd';
import Table, { ColumnProps } from 'antd/lib/table';
import React from 'react';
import LoadingComponent from '../../components/LoadingComponent/LoadingComponent';

export default function CommentsPage() {
  const {
    data,
    loading,
    fetchMore,
  }: AdminCommentConnectionQueryHookResult = useAdminCommentConnectionQuery();

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    adminCommentConnection: {
      nodes: comments,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<IComment>> = [
    {
      dataIndex: 'id',
      key: 'id',
      title: 'ID',
    },
    {
      dataIndex: 'author',
      key: 'author',
      render: (_, comment) => (
        <Space>
          <Avatar src={comment.author.avatarUrl} />
          {comment.author.name}
        </Space>
      ),
      title: 'Author',
    },
    {
      dataIndex: 'content',
      key: 'content',
      render: (content) => (
        <Popover content={content}>{content.slice(0, 140)}</Popover>
      ),
      title: 'content',
    },
    {
      dataIndex: 'article',
      key: 'article',
      render: (_, comment) => (
        <a href={`/articles/${comment.commentable.uuid}`}>
          {comment.commentable.title}
        </a>
      ),
      title: 'article',
    },
    {
      dataIndex: 'createdAt',
      key: 'createdAt',
      title: 'CreatedAt',
    },
    {
      dataIndex: 'deletedAt',
      key: 'deletedAt',
      render: (deletedAt) => <span>{deletedAt || '-'}</span>,
      title: 'deletedAt',
    },
    {
      dataIndex: 'actions',
      key: 'actions',
      render: (_, comment) => (
        <span>
          {comment.deletedAt ? (
            <Popconfirm title='Are you sure to recover this comment?'>
              Recover
            </Popconfirm>
          ) : (
            <Popconfirm title='Are you sure to delete this comment?'>
              Delete
            </Popconfirm>
          )}
        </span>
      ),
      title: 'Actions',
    },
  ];
  return (
    <div>
      <PageHeader title='Comments' />
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={comments}
        rowKey='id'
        pagination={false}
      />
      <div style={{ margin: '1rem', textAlign: 'center' }}>
        <Button
          type='link'
          loading={loading}
          disabled={!hasNextPage}
          onClick={() => {
            fetchMore({
              updateQuery: (prev, { fetchMoreResult }) => {
                if (!fetchMoreResult) {
                  return prev;
                }
                const connection = fetchMoreResult.adminCommentConnection;
                connection.nodes = prev.adminCommentConnection.nodes.concat(
                  connection.nodes,
                );
                return Object.assign({}, prev, {
                  adminCommentConnection: connection,
                });
              },
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
