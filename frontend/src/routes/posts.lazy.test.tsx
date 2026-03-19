import {render, screen, waitFor} from '@testing-library/react';
import {describe, it, expect} from 'vitest';import {MockedProvider} from '@apollo/client/testing';
import {GET_DATA} from '../queries/get_posts';
import {PostsPage} from './posts.lazy';

describe('PostsPage', () => {
  it('shows a loading spinner while fetching posts', () => {
    render(
      <MockedProvider mocks={[]} addTypename={false}>
        <PostsPage />
      </MockedProvider>,
    );
    expect(screen.getByRole('progressbar')).toBeDefined();
  });

  it('shows an error message when the query fails', async () => {
    const mocks = [
      {
        request: {query: GET_DATA},
        error: new Error('Network error'),
      },
    ];
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <PostsPage />
      </MockedProvider>,
    );
    await waitFor(() => {
      expect(screen.getByText(/Failed to load posts/i)).toBeDefined();
    });
  });

  it('renders no cards when there are no posts', async () => {
    const mocks = [
      {
        request: {query: GET_DATA},
        result: {data: {posts: []}},
      },
    ];
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <PostsPage />
      </MockedProvider>,
    );
    await waitFor(() => {
      expect(screen.queryByRole('article')).toBeNull();
    });
  });

  it('renders a card for each post with the correct title', async () => {
    const mocks = [
      {
        request: {query: GET_DATA},
        result: {
          data: {
            posts: [
              {id: '1', title: 'First Post', imageUrl: null, commentCounter: 0},
              {id: '2', title: 'Second Post', imageUrl: null, commentCounter: 0},
            ],
          },
        },
      },
    ];
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <PostsPage />
      </MockedProvider>,
    );
    await waitFor(() => {
      expect(screen.getByText('First Post')).toBeDefined();
      expect(screen.getByText('Second Post')).toBeDefined();
    });
  });
});
