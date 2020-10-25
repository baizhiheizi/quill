import Editor, { commands } from '@uiw/react-md-editor';
import { Button, Col, Form, Input, InputNumber, Row } from 'antd';
import React from 'react';

export function ArticleNew() {
  return (
    <Row justify='center'>
      <Col flex={1} xs={24} sm={24} md={18} lg={16}>
        <Form
          labelCol={{ span: 2 }}
          wrapperCol={{ span: 22 }}
          onFinish={(values) => console.log(values)}
        >
          <Form.Item label='Title' name='title'>
            <Input placeholder='Title of your article' />
          </Form.Item>
          <Form.Item label='Conent' name='content'>
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
          <Form.Item label='Intro' name='intro'>
            <Input.TextArea placeholder='Introduction of this article for your potential readers, 140 charater maxmum;' />
          </Form.Item>
          <Form.Item label='Price' name='price'>
            <InputNumber min={1} precision={4} defaultValue={1} />
          </Form.Item>
          <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 2 } }}>
            <Button type='primary' htmlType='submit'>
              Create
            </Button>
          </Form.Item>
        </Form>
      </Col>
    </Row>
  );
}
