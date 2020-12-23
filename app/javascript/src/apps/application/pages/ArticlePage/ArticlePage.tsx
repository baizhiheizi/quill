import {
  DislikeOutlined,
  HeartOutlined,
  LikeOutlined,
  ShareAltOutlined,
} from '@ant-design/icons';
import CommentsComponent from '@application/components/CommentsComponent/CommentsComponent';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import UserCardComponent from '@application/components/UserCardComponent/UserCardComponent';
import { handleShare, PAGE_TITLE } from '@application/shared';
import {
  ArticleQueryHookResult,
  useArticleQuery,
  useDownvoteArticleMutation,
  User,
  useUpvoteArticleMutation,
} from '@graphql';
import {
  MarkdownRendererComponent,
  useCurrentUser,
  usePrsdigg,
  useUserAgent,
} from '@shared';
import {
  Alert,
  Avatar,
  Button,
  Col,
  Divider,
  Progress,
  Row,
  Space,
  Statistic,
} from 'antd';
import moment from 'moment';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useParams } from 'react-router-dom';
import NotFoundPage from '../NotFoundPage/NotFoundPage';
import PayModalComponent from './components/PayModalComponent';
import RewardModalComponent from './components/RewardModalComponent';

export default function ArticlePage() {
  const { t } = useTranslation();
  const { uuid } = useParams<{ uuid: string }>();
  const [rewardModalVisible, setRewardModalVisible] = useState(false);
  const [payModalVisible, setPayModalVisible] = useState(false);
  const { appId } = usePrsdigg();
  const { mixinEnv } = useUserAgent();
  const currentUser = useCurrentUser();
  const { loading, data, refetch }: ArticleQueryHookResult = useArticleQuery({
    variables: { uuid },
  });
  const [upvoteArticle] = useUpvoteArticleMutation();
  const [downvoteArticle] = useDownvoteArticleMutation();

  useEffect(() => {
    return () => (document.title = PAGE_TITLE);
  }, [uuid]);

  if (loading) {
    return <LoadingComponent />;
  }

  const { article } = data;

  if (!article) {
    return <NotFoundPage />;
  }

  document.title = `${article.title} - ${article.author.name}`;

  return (
    <div>
      <h1>{article.title}</h1>
      <div style={{ color: '#aaa', marginBottom: '1rem' }}>
        <Space>
          <Avatar size='small' src={article.author.avatarUrl} />
          <span>{article.author.name}</span>
          <span>{moment(article.createdAt).format('YYYY/MM/DD HH:mm')}</span>
        </Space>
      </div>
      <div
        style={{
          background: '#f4f4f4',
          borderLeft: '5px solid #ddd',
          padding: '0.5rem 0.5rem',
          marginBottom: '2rem',
        }}
      >
        {article.intro}
      </div>
      {article.authorized ? (
        <MarkdownRendererComponent source={article.content} />
      ) : (
        <div style={{ textAlign: 'center' }}>
          <div
            style={{
              color: '#aaa',
              marginBottom: '1rem',
              textAlign: 'left',
            }}
          >
            {t('article.wordsCount')}: {article.wordsCount}
          </div>
          {article.partialContent && (
            <div style={{ marginBottom: '1rem', textAlign: 'left' }}>
              <MarkdownRendererComponent source={article.partialContent} />
              <div
                style={{ marginTop: '1rem', textAlign: 'center', color: 'red' }}
              >
                - {t('articlePage.moreToRead')} -
              </div>
            </div>
          )}
          <div style={{ marginBottom: '1rem' }}>
            <div>
              {t('articlePage.payToRead1')}{' '}
              <span style={{ color: 'red' }}>{article.price} PRS</span>{' '}
              {t('articlePage.payToRead2')}
            </div>
            <div>
              {t('articlePage.payToRead3')}{' '}
              <Link to='/rules'>{t('menu.rules')}</Link>{' '}
              {t('articlePage.payToRead4')}
            </div>
          </div>
          <div style={{ marginBottom: '1rem' }}>
            <Alert type='warning' message={t('articlePage.payWarning')} />
          </div>
          <div>
            {currentUser ? (
              <div>
                <Button type='primary' onClick={() => setPayModalVisible(true)}>
                  {article.readers.totalCount === 0
                    ? t('articlePage.firstReaderBtn')
                    : t('articlePage.payToReadBtn')}
                </Button>
                {payModalVisible && (
                  <PayModalComponent
                    visible={payModalVisible}
                    price={article.price}
                    walletId={article.walletId}
                    articleUuid={article.uuid}
                    paymentTraceId={article.paymentTraceId}
                    onCancel={() => {
                      setPayModalVisible(false);
                      refetch();
                    }}
                  />
                )}
                <div
                  style={{ marginTop: 10, fontSize: '0.8rem', color: '#aaa' }}
                >
                  {t('articlePage.alreadyPaid1')}{' '}
                  <a onClick={() => refetch()}>
                    {t('articlePage.alreadyPaid2')}
                  </a>
                </div>
                <div
                  style={{
                    marginTop: 5,
                    fontSize: '0.8rem',
                    color: '#aaa',
                  }}
                >
                  {t('articlePage.buyPRSTips')}
                </div>
              </div>
            ) : (
              <Button
                type='primary'
                href={`/login?return_to=${encodeURIComponent(location.href)}`}
              >
                {t('articlePage.loginBtn')}
              </Button>
            )}
          </div>
        </div>
      )}
      <div
        onClick={() => handleShare(article, Boolean(mixinEnv), appId)}
        style={{ margin: '20px 0', textAlign: 'right' }}
      >
        <Button type='link' icon={<ShareAltOutlined />}>
          {t('articlePage.shareBtn')}
        </Button>
      </div>
      <div style={{ marginBottom: '2rem' }}>
        <UserCardComponent user={article.author} />
      </div>
      <div style={{ marginBottom: '2rem' }}>
        <Row justify='center'>
          <Col>
            {article.authorized &&
            currentUser.mixinId !== article.author.mixinId ? (
              <Button
                type={article.upvoted ? 'primary' : 'default'}
                size='large'
                shape='circle'
                icon={<LikeOutlined />}
                onClick={() => {
                  if (!article.upvoted) {
                    upvoteArticle({
                      variables: { input: { uuid: article.uuid } },
                    });
                  }
                }}
              />
            ) : (
              <Button
                type='primary'
                size='large'
                shape='circle'
                icon={<LikeOutlined />}
              />
            )}
          </Col>
          <Col
            style={{
              marginTop: 10,
              minWidth: 100,
              padding: '0 20px',
              textAlign: 'center',
            }}
          >
            <Progress
              showInfo={false}
              percent={
                (article.upvotesCount /
                  (article.upvotesCount + article.downvotesCount)) *
                100
              }
              strokeColor='#1890ff'
              trailColor={
                article.upvotesCount + article.downvotesCount > 0
                  ? '#ff4d4f'
                  : null
              }
            />
            <div>
              {article.upvotesCount}:{article.downvotesCount}
            </div>
          </Col>
          <Col>
            {article.authorized &&
            currentUser.mixinId !== article.author.mixinId ? (
              <Button
                type={article.downvoted ? 'primary' : 'default'}
                danger={article.downvoted}
                size='large'
                shape='circle'
                icon={<DislikeOutlined />}
                onClick={() => {
                  if (!article.downvoted) {
                    downvoteArticle({
                      variables: { input: { uuid: article.uuid } },
                    });
                  }
                }}
              />
            ) : (
              <Button
                type='primary'
                size='large'
                danger
                shape='circle'
                icon={<DislikeOutlined />}
              />
            )}
          </Col>
        </Row>
      </div>
      {article.authorized && article.author.mixinId !== currentUser.mixinId && (
        <div style={{ marginBottom: '1rem' }}>
          <div style={{ textAlign: 'center' }}>
            <Button
              onClick={() => setRewardModalVisible(true)}
              shape='round'
              type='primary'
              size='large'
              danger
            >
              <HeartOutlined /> {t('articlePage.rewardBtn')}
            </Button>
            {rewardModalVisible && (
              <RewardModalComponent
                visible={rewardModalVisible}
                articleUuid={uuid}
                onCancel={() => {
                  setRewardModalVisible(false);
                  refetch();
                }}
                walletId={article.walletId}
              />
            )}
          </div>
        </div>
      )}
      {article.readers.nodes.length > 0 && (
        <div>
          <Row justify='center'>
            <Col>
              <h4>
                <span style={{ color: 'red' }}>
                  {article.buyOrders.totalCount}
                </span>{' '}
                {t('articlePage.timesBought')},{' '}
                <span style={{ color: 'red' }}>
                  {article.rewardOrders.totalCount}
                </span>{' '}
                {t('articlePage.timesReward')}
              </h4>
            </Col>
          </Row>
          <Row justify='center' style={{ marginBottom: '1rem' }}>
            <Col>
              <Avatar.Group>
                {article.readers.nodes.map((reader: Partial<User>) => (
                  <Avatar key={reader.mixinId} src={reader.avatarUrl}>
                    {reader.name[0]}
                  </Avatar>
                ))}
              </Avatar.Group>
            </Col>
          </Row>
          {article.authorized && (
            <Row gutter={16} style={{ textAlign: 'center' }}>
              <Col xs={12} sm={6}>
                <Statistic title={t('article.price')} value={article.price} />
              </Col>
              <Col xs={12} sm={6}>
                <Statistic
                  title={t('article.ordersCount')}
                  value={article.ordersCount}
                />
              </Col>
              <Col xs={12} sm={6}>
                <Statistic
                  title={t('article.revenue')}
                  value={article.revenue ? article.revenue.toFixed(4) : 0.0}
                />
              </Col>
              <Col xs={12} sm={6}>
                <Statistic
                  title={t('article.myShare')}
                  value={
                    article.myShare ? (article.myShare * 100).toFixed(3) : '0.0'
                  }
                />
              </Col>
            </Row>
          )}
        </div>
      )}
      <Divider />
      <CommentsComponent
        commentableType='Article'
        commentableId={article.id}
        authorized={article.authorized}
        commentingSubscribed={article.commentingSubscribed}
        articleUuid={article.uuid}
      />
    </div>
  );
}
