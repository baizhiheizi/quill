import { Col, Row, Select, Tabs } from 'antd';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import ArticlesComponent from './components/ArticlesComponents';
import CommentsComponent from './components/CommentsComponent';
import TagsComponent from './components/TagsComponent';

export default function HomePage() {
  const { t } = useTranslation();
  const [articlesOrder, setArticlesOrder] = useState<
    'default' | 'lately' | 'revenue'
  >('default');
  return (
    <Tabs defaultActiveKey='default'>
      <Tabs.TabPane tab={t('homePage.articles')} key='articles'>
        <Row justify='end'>
          <Col>
            <Select
              value={articlesOrder}
              bordered={false}
              onSelect={(value) => setArticlesOrder(value)}
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
