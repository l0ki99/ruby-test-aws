import {gql} from '@apollo/client';

export const CREATE_POST = gql`
  mutation CreatePost($title: String!, $content: String!) {
    createPost(input: {title: $title, content: $content}) {
      post {
        id
        title
        content
      }
      errors
    }
  }
`;
