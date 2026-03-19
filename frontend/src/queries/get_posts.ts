import {gql} from '@apollo/client';

export const GET_DATA = gql`
  query GetData {
    posts {
      id
      title
      content
      imageUrl
      commentCounter
    }
  }
`;
