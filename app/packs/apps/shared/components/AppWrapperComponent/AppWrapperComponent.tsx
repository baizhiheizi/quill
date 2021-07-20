import { ApolloProvider } from '@apollo/client';
import { message, Modal } from 'antd';
import {
  apolloClient,
  CurrentUserContext,
  hideLoader,
  mixinContext,
  PhotoSwipeContext,
  PrsdiggContext,
  UserAgentContext,
} from 'apps/shared';
import consumer from 'channels/consumer';
// https://github.com/apollographql/apollo-client/issues/6381
import 'core-js/features/promise';
import { User } from 'graphqlTypes';
import isMobile from 'ismobilejs';
import PhotoSwipeLightbox from 'photoswipe/dist/photoswipe-lightbox.esm';
import 'photoswipe/dist/photoswipe.css';
import PhotoSwipe from 'photoswipe/dist/photoswipe.esm.js';
import React, { Suspense, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import LoadingComponent from '../LoadingComponent/LoadingComponent';

export function AppWrapperComponent(props: {
  csrfToken: string;
  currentUser?: Partial<User>;
  prsdigg: {
    appId: string;
    pageTitle?: string;
    attachmentEndpoint?: string;
    appName?: string;
  };
  defaultLocale: 'en' | 'ja' | 'zh-CN';
  availableLocales: [string];
  children: React.ReactChild;
}) {
  const { csrfToken, prsdigg, currentUser: _currentUser, children } = props;
  const [currentUser, setCurrentUser] = useState(
    _currentUser && _currentUser.accessable ? _currentUser : null,
  );
  const { t } = useTranslation();

  const lightbox = new PhotoSwipeLightbox({
    gallerySelector: '.photoswipe-gallery',
    childSelector: 'a.photoswipe',
    pswpModule: PhotoSwipe,
    mainClass: mixinContext?.immersive ? 'immersive' : '',
  });

  useEffect(() => {
    hideLoader();
  }, []);

  useEffect(() => {
    if (!currentUser) {
      return;
    }
    consumer.subscriptions.create('Noticed::NotificationChannel', {
      connected() {
        console.log('Action Cable Connected');
      },
      disconnected() {
        console.log('Action Cable disconnected');
      },
      received(data: any) {
        message.info(data);
      },
    });
  }, [currentUser]);

  useEffect(() => {
    if (!_currentUser || _currentUser.accessable) {
      return;
    } else if (!_currentUser.mixinAuthorizationValid) {
      Modal.info({
        title: t('invalid_authorization'),
        content: t('please_confirm_all_authorizations_required'),
        okText: t('reauthorize'),
        onOk: () => location.replace('/login'),
      });
    } else if (!_currentUser.accessable) {
      Modal.error({
        title: t('no_access'),
        content: t('sorry_you_are_not_authorized_to_access_this_application'),
        okText: t('logout'),
        onOk: () => location.replace('/logout'),
      });
    }
  }, [_currentUser]);

  return (
    <Suspense fallback={<LoadingComponent />}>
      <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
        <PrsdiggContext.Provider value={prsdigg}>
          <UserAgentContext.Provider
            value={{
              mixinAppearance: mixinContext.appearance,
              mixinCurrency: mixinContext.currency,
              mixinAppversion: mixinContext.appVersion,
              mixinConversationId: mixinContext.conversationId,
              mixinEnv: mixinContext.platform,
              mixinImmersive: mixinContext.immersive,
              isMobile: isMobile(),
            }}
          >
            <CurrentUserContext.Provider
              value={{ currentUser, setCurrentUser }}
            >
              <PhotoSwipeContext.Provider value={{ lightbox }}>
                {children}
              </PhotoSwipeContext.Provider>
            </CurrentUserContext.Provider>
          </UserAgentContext.Provider>
        </PrsdiggContext.Provider>
      </ApolloProvider>
    </Suspense>
  );
}
