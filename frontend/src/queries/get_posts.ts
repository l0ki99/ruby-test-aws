import {gql} from '@apollo/client';

export const GET_DATA = gql`
  query GetData($page: Int, $perPage: Int) {
    posts(page: $page, perPage: $perPage) {
      id
      title
      content
      imageUrl
      commentCounter
    }
  }
`;
