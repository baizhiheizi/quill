import {
  DislikeOutlined,
  LikeOutlined,
  MessageOutlined,
  PayCircleOutlined,
  ShareAltOutlined,
} from '@ant-design/icons';
import { Article } from '@graphql';
import { usePrsdigg, useUserAgent } from '@shared';
import { Avatar, Button, List, Popover, Row, Space, Typography } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { handleArticleShare } from '../../shared';
import ArticleTagsComponent from '../ArticleTagsComponent/ArticleTagsComponent';
import UserCardComponent from '../UserCardComponent/UserCardComponent';

export default function ArticleListItemComponent(props: {
  article: Partial<Article>;
}) {
  const { mixinEnv } = useUserAgent();
  const { appId } = usePrsdigg();
  const { i18n } = useTranslation();
  moment.locale(i18n.language);
  const { article } = props;
  return (
    <List.Item
      style={{ padding: '1rem 0.5rem' }}
      key={article.uuid}
      actions={
        article.upvoteRatio === null
          ? [
              <RevenueAction
                revenueUsd={article.revenueUsd}
                currencySymbol={article.currency.symbol}
              />,
              <CommentsCountAction commentsCount={article.commentsCount} />,
              <ShareAction
                article={article}
                mixinEnv={mixinEnv}
                appId={appId}
              />,
            ]
          : [
              <RevenueAction
                revenueUsd={article.revenueUsd}
                currencySymbol={article.currency.symbol}
              />,
              <CommentsCountAction commentsCount={article.commentsCount} />,
              <UpdateVoteRatioAction upvoteRatio={article.upvoteRatio} />,
              <ShareAction
                article={article}
                mixinEnv={mixinEnv}
                appId={appId}
              />,
            ]
      }
    >
      <List.Item.Meta
        style={{ marginBottom: 0 }}
        avatar={
          <Popover
            content={<UserCardComponent user={article.author} />}
            placement='bottomLeft'
          >
            <Avatar src={article.author.avatarUrl}>
              {article.author.name[0]}
            </Avatar>
          </Popover>
        }
        title={
          <Row>
            <div>
              <div>{article.author.name}</div>
              <div style={{ fontSize: '0.8rem', color: '#aaa' }}>
                {moment(article.createdAt).fromNow()}
              </div>
            </div>
            <div style={{ position: 'relative', marginLeft: 'auto' }}>
              <Space style={{ marginLeft: 'auto' }}>
                <Avatar size='small' src={article.currency.iconUrl} />
                <span>
                  {article.currency.symbol === 'BTC'
                    ? article.price.toFixed(6)
                    : article.price.toFixed(2)}
                </span>
              </Space>
              <div
                style={{ position: 'absolute', right: 0, fontSize: '0.8rem' }}
              >
                <Typography.Text type='secondary'>
                  ≈ ${article.priceUsd}
                </Typography.Text>
              </div>
            </div>
          </Row>
        }
      />
      <Link style={{ color: 'initial' }} to={`/articles/${article.uuid}`}>
        <h2>{article.title}</h2>
        <p>{article.intro}</p>
      </Link>
      <ArticleTagsComponent tags={article.tags} />
    </List.Item>
  );
}

function RevenueAction(props: { revenueUsd: number; currencySymbol: string }) {
  return (
    <Space>
      <PayCircleOutlined />
      <span>{props.revenueUsd.toFixed(2)}</span>
    </Space>
  );
}

function CommentsCountAction(props: { commentsCount: number }) {
  return (
    <Space>
      <MessageOutlined />
      <span>{props.commentsCount}</span>
    </Space>
  );
}
function UpdateVoteRatioAction(props: { upvoteRatio: number }) {
  const { upvoteRatio } = props;
  return (
    <Space
      style={upvoteRatio >= 50 ? { color: '#1890ff' } : { color: '#ff4d4f' }}
    >
      {upvoteRatio >= 50 ? <LikeOutlined /> : <DislikeOutlined />}
      <span>{upvoteRatio === null ? '' : `${upvoteRatio}%`}</span>
    </Space>
  );
}

function ShareAction(props: {
  article: Partial<Article>;
  mixinEnv: boolean;
  appId: string;
}) {
  return (
    <Button
      size='small'
      type='text'
      icon={
        <ShareAltOutlined
          onClick={() => {
            handleArticleShare(
              props.article,
              Boolean(props.mixinEnv),
              props.appId,
            );
          }}
        />
      }
    />
  );
}
