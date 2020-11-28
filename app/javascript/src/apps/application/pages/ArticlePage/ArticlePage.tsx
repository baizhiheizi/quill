import {
  DislikeOutlined,
  HeartOutlined,
  LikeOutlined,
  ShareAltOutlined,
} from '@ant-design/icons';
import CommentsComponent from '@application/components/CommentsComponent/CommentsComponent';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import MarkdownRendererComponent from '@application/components/MarkdownRendererComponent/MarkdownRendererComponent';
import UserCardComponent from '@application/components/UserCardComponent/UserCardComponent';
import {
  handleShare,
  PAGE_TITLE,
  useCurrentUser,
  usePrsdigg,
  useUserAgent,
} from '@application/shared';
import {
  ArticleQueryHookResult,
  useArticleQuery,
  useDownvoteArticleMutation,
  User,
  useUpvoteArticleMutation,
} from '@graphql';
import {
  Alert,
  Avatar,
  Button,
  Col,
  Divider,
  Modal,
  Progress,
  Radio,
  Row,
  Space,
  Statistic,
} from 'antd';
import { encode as encode64 } from 'js-base64';
import moment from 'moment';
import QRCode from 'qrcode.react';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useParams } from 'react-router-dom';
import { v4 as uuidv4 } from 'uuid';
import NotFoundPage from '../NotFoundPage/NotFoundPage';
import './ArticlePage.less';
import PayModalComponent from './components/PayModalComponent';

export default function ArticlePage() {
  const { t } = useTranslation();
  const { uuid } = useParams<{ uuid: string }>();
  const [paying, setPaying] = useState(false);
  const [rewardModalVisible, setRewardModalVisible] = useState(false);
  const [payModalVisible, setPayModalVisible] = useState(false);
  const [rewardAmount, setRewardAmount] = useState(1);
  const { appId } = usePrsdigg();
  const { mixinEnv } = useUserAgent();
  const currentUser = useCurrentUser();
  const {
    loading,
    data,
    refetch,
    startPolling,
    stopPolling,
  }: ArticleQueryHookResult = useArticleQuery({
    variables: { uuid },
  });
  const [upvoteArticle] = useUpvoteArticleMutation();
  const [downvoteArticle] = useDownvoteArticleMutation();

  useEffect(() => {
    return () => (document.title = PAGE_TITLE);
  }, [uuid]);

  useEffect(() => {
    return () => stopPolling();
  }, [startPolling, stopPolling]);

  if (loading) {
    return <LoadingComponent />;
  }

  const { article } = data;

  if (!article) {
    return <NotFoundPage />;
  }

  if (article.authorized) {
    stopPolling();
  }

  document.title = `${article.title} - ${article.author.name}`;

  const QRCodeModalContent = ({ url, type = 'pay' }) => (
    <div style={{ textAlign: 'center' }}>
      <div style={{ marginBottom: 5 }}>
        <QRCode value={url} size={200} />
      </div>
      <div style={{ color: '#aaa' }}>
        {type === 'pay'
          ? t('messages.payWithMessenger')
          : t('messages.viewWithMessenger')}
      </div>
    </div>
  );

  const handleRewarding = () => {
    const payUrl = `mixin://pay?recipient=${
      article.walletId || appId
    }&trace=${uuidv4()}&memo=${encode64(
      JSON.stringify({ t: 'REWARD', a: uuid }),
    )}&asset=${article.assetId}&amount=${rewardAmount.toFixed(8)}`;
    if (mixinEnv) {
      location.replace(payUrl);
    } else {
      Modal.confirm({
        icon: null,
        centered: true,
        content: <QRCodeModalContent url={payUrl} />,
        okText: t('common.paidBtn'),
        cancelText: t('common.cancelBtn'),
      });
    }
    setRewardModalVisible(false);
  };
  const handleRedirectingRobot = (url: string) => {
    if (mixinEnv) {
      location.replace(url);
    } else {
      Modal.info({
        icon: null,
        centered: true,
        content: <QRCodeModalContent url={url} type='user' />,
      });
    }
  };

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
              paying ? (
                <div>
                  <div>
                    <Button type='primary' loading disabled danger>
                      {t('articlePage.pollingPayment')}
                    </Button>
                  </div>
                  <div>
                    <Button
                      type='link'
                      onClick={() => {
                        setPaying(false);
                        stopPolling();
                      }}
                    >
                      {t('common.cancelBtn')}
                    </Button>
                  </div>
                </div>
              ) : (
                <div>
                  <Button
                    type='primary'
                    onClick={() => setPayModalVisible(true)}
                  >
                    {article.readers.totalCount === 0
                      ? t('articlePage.firstReaderBtn')
                      : t('articlePage.payToReadBtn')}
                  </Button>
                  <PayModalComponent
                    visible={payModalVisible}
                    price={article.price}
                    walletId={article.walletId}
                    articleUuid={article.uuid}
                    onCancel={() => setPayModalVisible(false)}
                  />
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
                    {t('articlePage.buyPRSTips1')}{' '}
                    <a
                      onClick={() => {
                        handleRedirectingRobot(
                          'mixin://users/61103d28-3ac2-44a2-ae34-bd956070dab1',
                        );
                      }}
                    >
                      ExinOne
                    </a>{' '}
                    {t('articlePage.buyPRSTips2')}{' '}
                    <a
                      onClick={() => {
                        handleRedirectingRobot(
                          'mixin://users/a753e0eb-3010-4c4a-a7b2-a7bda4063f62',
                        );
                      }}
                    >
                      4swap
                    </a>{' '}
                  </div>
                </div>
              )
            ) : (
              <Button
                type='primary'
                href={`/login?redirect_uri=${encodeURIComponent(
                  location.href,
                )}`}
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
            <Modal
              className='reward-modal'
              centered
              closable={false}
              title={t('articlePage.rewardModal.title')}
              okText={t('articlePage.rewardModal.okText')}
              cancelText={t('articlePage.rewardModal.cancelText')}
              visible={rewardModalVisible}
              onCancel={() => setRewardModalVisible(false)}
              onOk={handleRewarding}
            >
              <Radio.Group
                options={[
                  { label: '1', value: 1 },
                  { label: '8', value: 8 },
                  { label: '32', value: 32 },
                  { label: '64', value: 64 },
                  { label: '256', value: 256 },
                  { label: '1024', value: 1024 },
                ]}
                value={rewardAmount}
                onChange={(e) => setRewardAmount(e.target.value)}
                optionType='button'
              />
            </Modal>
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
