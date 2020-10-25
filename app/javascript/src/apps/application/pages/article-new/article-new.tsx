import { useCreateArticleMutation } from '@/graphql';
import Editor, { commands } from '@uiw/react-md-editor';
import { Button, Form, Input, InputNumber, message } from 'antd';
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
        message.success('Created!');
        history.replace('/');
      }
    },
  });
  return (
    <Form
      labelCol={{ span: 2 }}
      wrapperCol={{ span: 22 }}
      onFinish={(values) => createArticle({ variables: { input: values } })}
    >
      <Form.Item label='Title' name='title' rules={[{ required: true }]}>
        <Input placeholder='Title of your article' />
      </Form.Item>
      <Form.Item label='Conent' name='content' rules={[{ required: true }]}>
        <Editor
          preview='edit'
          placeholder='Markdown supported'
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
      <Form.Item label='Intro' name='intro' rules={[{ required: true }]}>
        <Input.TextArea placeholder='Introduction of this article for your potential readers, 140 charater maxmum;' />
      </Form.Item>
      <Form.Item label='Price' name='price' rules={[{ required: true }]}>
        <InputNumber min={1} precision={4} />
      </Form.Item>
      <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 2 } }}>
        <Button type='primary' htmlType='submit' loading={loading}>
          Create
        </Button>
      </Form.Item>
    </Form>
  );
}
