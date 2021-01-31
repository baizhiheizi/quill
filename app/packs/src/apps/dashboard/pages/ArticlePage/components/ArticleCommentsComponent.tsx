import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import { Comment as IComment, useCommentConnectionQuery } from '@graphql';
import { MarkdownRendererComponent, useUserAgent } from '@shared';
import { Avatar, Button, Comment, List } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';

export default function ArticleCommentsComponent(props: { articleId: string }) {
  const { articleId } = props;
  const { t, i18n } = useTranslation();
  const { isMobile } = useUserAgent();
  moment.locale(i18n.language);
  const { loading, data, fetchMore } = useCommentConnectionQuery({
    variables: {
      commentableType: 'Article',
      commentableId: articleId,
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

  return (
    <div>
      <List
        size='small'
        dataSource={comments}
        loadMore={
          hasNextPage && (
            <div
              style={{
                textAlign: 'center',
                marginTop: 12,
                height: 32,
                lineHeight: '32px',
              }}
            >
              <Button
                loading={loading}
                onClick={() => {
                  fetchMore({
                    variables: {
                      after: endCursor,
                      type: 'author',
                    },
                  });
                }}
              >
                {t('common.loadMore')}
              </Button>
            </div>
          )
        }
        renderItem={(comment: Partial<IComment>) => (
          <List.Item key={comment.id}>
            <div
              id={`comment-${comment.id}`}
              className={isMobile.phone ? 'blockquote-collapsed' : ''}
            >
              {comment.deletedAt ? (
                <div
                  style={{
                    padding: '1rem 0',
                    color: '#aaa',
                    textDecoration: 'line-through',
                  }}
                >
                  {t('commentsComponent.deletedText')}
                </div>
              ) : (
                <Comment
                  author={comment.author.name}
                  avatar={
                    <Avatar src={comment.author.avatarUrl}>
                      {comment.author.name[0]}
                    </Avatar>
                  }
                  content={
                    <MarkdownRendererComponent source={comment.content} />
                  }
                  datetime={
                    <span>
                      {moment(comment.createdAt).format('YYYY-MM-DD HH:mm:ss')}
                    </span>
                  }
                />
              )}
            </div>
          </List.Item>
        )}
      />
    </div>
  );
}
