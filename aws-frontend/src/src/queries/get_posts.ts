import {gql} from '@apollo/client';

export const GET_DATA = gql`
  query GetData($page: Int, $perPage: Int, $sortBy: PostSortEnum) {
    posts(page: $page, perPage: $perPage, sortBy: $sortBy) {
      id
      title
      content
      imageUrl
      commentCounter
    }
  }
`;
