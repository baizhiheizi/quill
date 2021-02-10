import { Col, Row, Select, Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useHistory, useLocation } from 'react-router-dom';
import ArticlesComponent from './components/ArticlesComponents';
import CommentsComponent from './components/CommentsComponent';
import TagsComponent from './components/TagsComponent';

export default function HomePage() {
  const { t } = useTranslation();
  const history = useHistory();
  const location = useLocation<any>();
  console.log(location);
  const [activeTabKey, setActiveTabKey] = useState<
    'default' | 'tags' | 'comments'
  >(location.state?.activeTabKey || 'default');
  const [articlesOrder, setArticlesOrder] = useState<
    'default' | 'lately' | 'revenue'
  >(location.state?.articlesOrder || 'default');
  return (
    <Tabs
      defaultActiveKey={activeTabKey}
      onChange={(activeKey: any) => {
        setActiveTabKey(activeKey);
        history.replace({
          ...history.location,
          state: { activeTabKey: activeKey, articlesOrder },
        });
      }}
    >
      <Tabs.TabPane tab={t('homePage.articles')} key='articles'>
        <Row justify='end'>
          <Col>
            <Select
              value={articlesOrder}
              bordered={false}
              onSelect={(value) => {
                setArticlesOrder(value);
                history.replace({
                  ...history.location,
                  state: { activeTabKey, articlesOrder: value },
                });
              }}
            >
              <Select.Option value='default'>
                {t('homePage.articlesOrder.popularity')}
              </Select.Option>
              <Select.Option value='lately'>
                {t('homePage.articlesOrder.lately')}
              </Select.Option>
              <Select.Option value='revenue'>
                {t('homePage.articlesOrder.revenue')}
              </Select.Option>
            </Select>
          </Col>
        </Row>
        <ArticlesComponent order={articlesOrder} />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('homePage.tags')} key='tags'>
        <TagsComponent />
      </Tabs.TabPane>
      <Tabs.TabPane tab={t('homePage.commentsZone')} key='comments'>
        <CommentsComponent />
      </Tabs.TabPane>
    </Tabs>
  );
}
