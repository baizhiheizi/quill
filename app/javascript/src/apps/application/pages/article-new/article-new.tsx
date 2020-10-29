import { useCreateArticleMutation } from '@/graphql';
import Editor, { commands } from '@uiw/react-md-editor';
import { Button, Form, Input, InputNumber, message, Modal } from 'antd';
import React from 'react';
import { useHistory } from 'react-router-dom';

export function ArticleNew() {
  const history = useHistory();
  const [createArticle, { loading }] = useCreateArticleMutation({
    update(
      _,
      {
        data: {
          createArticle: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success('文章发布成功');
        history.replace('/');
      }
    },
  });
  return (
    <Form
      labelCol={{ span: 2 }}
      wrapperCol={{ span: 22 }}
      onFinish={(values) => {
        const { title, content, price, intro } = values;
        if (!title || !content || !price || !intro) {
          message.warn('请先完成你的文章');
        } else {
          Modal.confirm({
            title: '确定要发布你的文章吗？',
            okText: '发布',
            cancelText: '再改改',
            onOk: () => createArticle({ variables: { input: values } }),
          });
        }
      }}
    >
      <Form.Item label='标题' name='title'>
        <Input placeholder='文章标题' />
      </Form.Item>
      <Form.Item label='正文' name='content'>
        <Editor
          textareaProps={{ placeholder: '写点有价值的东西' }}
          autoFocus={false}
          preview='edit'
          placeholder='支持 Markdown 格式'
          height={500}
          commands={[
            commands.bold,
            commands.italic,
            commands.quote,
            commands.hr,
            commands.title,
            commands.divider,
            commands.link,
            commands.code,
          ]}
        />
      </Form.Item>
      <Form.Item label='简介' name='intro'>
        <Input.TextArea placeholder='请简要介绍一下你的文章，简介内容为公开可见。' />
      </Form.Item>
      <Form.Item label='价格(PRS)' name='price'>
        <InputNumber min={1} precision={4} placeholder='1.0' />
      </Form.Item>
      <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 2 } }}>
        <Button size='large' type='primary' htmlType='submit' loading={loading}>
          发布
        </Button>
      </Form.Item>
    </Form>
  );
}
