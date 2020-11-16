import { Tabs } from 'antd';
import React from 'react';
import ArticlesComponent from './components/ArticlesComponents';
import CommentsComponent from './components/CommentsComponent';

export default function HomePage() {
  return (
    <Tabs defaultActiveKey='default'>
      <Tabs.TabPane tab='综合排序' key='default'>
        <ArticlesComponent order='default' />
      </Tabs.TabPane>
      <Tabs.TabPane tab='最新优先' key='lately'>
        <ArticlesComponent order='lately' />
      </Tabs.TabPane>
      <Tabs.TabPane tab='营收最多' key='revenue'>
        <ArticlesComponent order='revenue' />
      </Tabs.TabPane>
      <Tabs.TabPane tab='评论区' key='comments'>
        <CommentsComponent />
      </Tabs.TabPane>
    </Tabs>
  );
}
