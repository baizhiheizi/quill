import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import {
  Comment as IComment,
  useAdminDeleteCommentMutation,
  useAdminRecoverCommentMutation,
  useCommentConnectionQuery,
} from '@graphql';
import { Avatar, Button, message, Popconfirm, Popover, Space } from 'antd';
import Table, { ColumnProps } from 'antd/lib/table';
import React from 'react';

export default function CommentsComponent(props: {
  commentableId?: string;
  commentableType?: string;
  authorMixinId?: string;
}) {
  const { commentableId, commentableType, authorMixinId } = props;
  const { data, loading, fetchMore, refetch } = useCommentConnectionQuery({
    variables: { commentableId, commentableType, authorMixinId },
  });
  const [deleteComment, { loading: deleting }] = useAdminDeleteCommentMutation({
    update(_, { data: { error: err } }) {
      if (err) {
        message.error(err);
      } else {
        message.success('Successfully deleted!');
        refetch();
      }
    },
  });
  const [recover, { loading: recovering }] = useAdminRecoverCommentMutation({
    update(_, { data: { error: err } }) {
      if (err) {
        message.error(err);
      } else {
        message.success('Successfully recovered!');
        refetch();
      }
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    commentConnection: {
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
        <Popover content={content}>
          <div style={{ maxWidth: '100%' }}>
            {content ? content.slice(0, 140) : '-'}
          </div>
        </Popover>
      ),
      title: 'content',
    },
    {
      dataIndex: 'article',
      key: 'article',
      render: (_, comment) => (
        <a href={`/articles/${comment.commentable.uuid}`} target='_blank'>
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
            <Popconfirm
              title='Are you sure to recover this comment?'
              onConfirm={() =>
                recover({ variables: { input: { id: comment.id } } })
              }
            >
              <Button type='link' disabled={recovering}>
                Recover
              </Button>
            </Popconfirm>
          ) : (
            <Popconfirm
              title='Are you sure to delete this comment?'
              onConfirm={() =>
                deleteComment({ variables: { input: { id: comment.id } } })
              }
            >
              <Button type='link' disabled={deleting}>
                Delete
              </Button>
            </Popconfirm>
          )}
        </span>
      ),
      title: 'Actions',
    },
  ];
  return (
    <div>
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
