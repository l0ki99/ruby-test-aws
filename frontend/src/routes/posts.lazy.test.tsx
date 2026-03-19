import {render, screen, waitFor} from '@testing-library/react';
import {describe, it, expect, vi, afterEach} from 'vitest';
import {MockedProvider} from '@apollo/client/testing';
import {GET_DATA} from '../queries/get_posts';
import {PostsPage} from './posts.lazy';

describe('PostsPage', () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

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

  it('passes imageUrl to PostCard so the image is rendered', async () => {
    vi.stubEnv('VITE_API_BASE_URL', 'http://test-api:8090');
    const mocks = [
      {
        request: {query: GET_DATA},
        result: {
          data: {
            posts: [
              {id: '1', title: 'Cat Post', imageUrl: '/cat.png', commentCounter: 0},
              {id: '2', title: 'No Image Post', imageUrl: null, commentCounter: 0},
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
      const images = screen.getAllByRole('img');
      const srcs = images.map((img) => img.getAttribute('src'));
      expect(srcs).toContain('http://test-api:8090/cat.png');
    });
  });
});
