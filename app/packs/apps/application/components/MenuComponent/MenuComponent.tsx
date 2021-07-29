import {
  GithubOutlined,
  GlobalOutlined,
  NotificationOutlined,
} from '@ant-design/icons';
import { Badge, Col, Menu, Row } from 'antd';
import { OPEN_SOURCE_URL } from 'apps/application/shared';
import { imagePath, useCurrentUser, usePrsdigg } from 'apps/shared';
import { useCreateArticleMutation } from 'graphqlTypes';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import LoginModalComponent from '../LoginModalComponent/LoginModalComponent';

export default function MenuComponent(props: {
  mode: 'horizontal' | 'vertical';
  setDrawerVisible?: (visible: boolean) => void;
}) {
  const { currentUser } = useCurrentUser();
  const { logoFile } = usePrsdigg();
  const { mode, setDrawerVisible } = props;
  const { t, i18n } = useTranslation();

  const [createArticle] = useCreateArticleMutation({
    update: (
      _,
      {
        data: {
          createArticle: { uuid },
        },
      },
    ) => {
      location.replace(`/dashboard/articles/${uuid}/edit`);
    },
  });

  const toggleDrawer = () => {
    setDrawerVisible && setDrawerVisible(false);
  };

  return (
    <Row
      justify='center'
      style={
        mode === 'horizontal'
          ? { flexWrap: 'nowrap' }
          : { flexDirection: 'column', textAlign: 'center' }
      }
    >
      <Col>
        {currentUser && mode === 'vertical' ? (
          <a
            className='flex items-center justify-center block h-full m-4'
            href='/dashboard'
          >
            <img className='w-10 h-10 rounded-full' src={currentUser.avatar} />
          </a>
        ) : (
          <Link
            className='flex items-center justify-center h-full mx-4'
            to='/'
            replace
          >
            <img className='w-10 h-10' src={imagePath(logoFile)} />
          </Link>
        )}
      </Col>
      <Col flex={1}>
        <Menu theme='light' mode={mode} selectable={false}>
          <Menu.Item key='read' onClick={toggleDrawer}>
            <Link to='/' replace>
              {t('read')}
            </Link>
          </Menu.Item>
          <Menu.Item key='write' onClick={toggleDrawer}>
            {currentUser ? (
              <a onClick={() => createArticle()}>{t('write')}</a>
            ) : (
              <LoginModalComponent>
                <a>{t('write')}</a>
              </LoginModalComponent>
            )}
          </Menu.Item>
          <Menu.Item key='search' onClick={toggleDrawer}>
            <Link to='/search' replace>
              {t('search')}
            </Link>
          </Menu.Item>
          <Menu.Item key='rules' onClick={toggleDrawer}>
            <Link to='/rules' replace>
              {t('rules')}
            </Link>
          </Menu.Item>
          <Menu.Item key='fair' onClick={toggleDrawer}>
            <Link to='/fair' replace>
              {t('fair')}
            </Link>
          </Menu.Item>
          <Menu.Item key='open_source' onClick={toggleDrawer}>
            <a href={OPEN_SOURCE_URL} target='_blank'>
              <GithubOutlined className='mr-2' />
              {t('open_source')}
            </a>
          </Menu.Item>
        </Menu>
      </Col>
      <Col flex={1}>
        <Menu theme='light' mode={mode} selectable={false}>
          {i18n.languages.length > 1 && (
            <>
              <Menu.SubMenu
                className='ml-auto'
                key='global'
                title={
                  mode === 'horizontal' ? (
                    <GlobalOutlined />
                  ) : i18n.language.includes('en') ? (
                    'Language'
                  ) : i18n.language.includes('ja') ? (
                    '言語'
                  ) : (
                    '语言'
                  )
                }
              >
                {i18n.languages.map((lng) => {
                  if (lng.includes('CN')) {
                    return (
                      <Menu.Item key={lng}>
                        <a onClick={() => i18n.changeLanguage('zh-CN')}>中文</a>
                      </Menu.Item>
                    );
                  } else if (lng.includes('en')) {
                    return (
                      <Menu.Item key={lng}>
                        <a onClick={() => i18n.changeLanguage('en')}>EN</a>
                      </Menu.Item>
                    );
                  } else if (lng.includes('ja')) {
                    return (
                      <Menu.Item key={lng}>
                        <a onClick={() => i18n.changeLanguage('ja')}>日本語</a>
                      </Menu.Item>
                    );
                  }
                })}
              </Menu.SubMenu>
            </>
          )}
          {currentUser ? (
            <>
              <Menu.Item
                className={i18n.languages.length < 2 && 'ml-auto'}
                key='notifications'
                onClick={toggleDrawer}
              >
                <Badge dot={currentUser.unreadNotificationsCount > 0}>
                  <a href='/dashboard/notifications'>
                    {mode === 'horizontal' ? (
                      <NotificationOutlined />
                    ) : (
                      t('notifications_manage')
                    )}
                  </a>
                </Badge>
              </Menu.Item>
              <Menu.Item key='dashboard' onClick={toggleDrawer}>
                <a href='/dashboard' target='_blank'>
                  {t('dashboard')}
                </a>
              </Menu.Item>
              <Menu.Item key='logout' onClick={toggleDrawer}>
                <a href='/logout'>{t('logout')}</a>
              </Menu.Item>
            </>
          ) : (
            <Menu.Item key='login' onClick={toggleDrawer}>
              <LoginModalComponent>
                <a>{t('connect_wallet')}</a>
              </LoginModalComponent>
            </Menu.Item>
          )}
        </Menu>
      </Col>
    </Row>
  );
}
