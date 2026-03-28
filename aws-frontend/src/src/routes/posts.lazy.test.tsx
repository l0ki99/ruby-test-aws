import {render, screen, waitFor, fireEvent} from '@testing-library/react';
import {describe, it, expect, vi, afterEach} from 'vitest';
import {MockedProvider} from '@apollo/client/testing';
import {GET_DATA} from '../queries/get_posts';
import {PostsPage, PAGE, PER_PAGE} from './posts.lazy';

const DEFAULT_VARIABLES = {page: PAGE, perPage: PER_PAGE, sortBy: 'NEWEST'};

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

  it('shows a network error message when the request fails', async () => {
    const mocks = [
      {
        request: {query: GET_DATA, variables: DEFAULT_VARIABLES},
        error: new Error('Failed to fetch'),
      },
    ];
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <PostsPage />
      </MockedProvider>,
    );
    await waitFor(() => {
      expect(screen.getByText(/Network error: unable to reach the server/i)).toBeDefined();
    });
  });

  it('shows a GraphQL error message when the server returns an error', async () => {
    const mocks = [
      {
        request: {query: GET_DATA, variables: DEFAULT_VARIABLES},
        result: {errors: [{message: 'Rate limit exceeded. Try again later.'}]},
      },
    ];
    render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <PostsPage />
      </MockedProvider>,
    );
    await waitFor(() => {
      expect(screen.getByText(/Rate limit exceeded/i)).toBeDefined();
    });
  });

  it('renders no cards when there are no posts', async () => {
    const mocks = [
      {
        request: {query: GET_DATA, variables: DEFAULT_VARIABLES},
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
        request: {query: GET_DATA, variables: DEFAULT_VARIABLES},
        result: {
          data: {
            posts: [
              {id: '1', title: 'First Post', content: 'First content', imageUrl: null, commentCounter: 0},
              {id: '2', title: 'Second Post', content: 'Second content', imageUrl: null, commentCounter: 0},
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

  it('passes commentCounter to PostCard so the count is displayed', async () => {
    const mocks = [
      {
        request: {query: GET_DATA, variables: DEFAULT_VARIABLES},
        result: {
          data: {
            posts: [
              {id: '1', title: 'Busy Post', content: 'Busy content', imageUrl: null, commentCounter: 7},
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
      expect(screen.getByText('(7)')).toBeDefined();
    });
  });

  it('passes imageUrl to PostCard so the image is rendered', async () => {
    vi.stubEnv('VITE_API_BASE_URL', 'http://test-api:8090');
    const mocks = [
      {
        request: {query: GET_DATA, variables: DEFAULT_VARIABLES},
        result: {
          data: {
            posts: [
              {id: '1', title: 'Cat Post', content: 'Cat content', imageUrl: '/cat.png', commentCounter: 0},
              {id: '2', title: 'No Image Post', content: 'No image content', imageUrl: null, commentCounter: 0},
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

  it('renders a sort dropdown defaulting to Newest first', () => {
    render(
      <MockedProvider mocks={[]} addTypename={false}>
        <PostsPage />
      </MockedProvider>,
    );
    expect(screen.getByText('Newest first')).toBeDefined();
  });

  it('refetches with OLDEST sort when the user changes the dropdown', async () => {
    const newestMock = {
      request: {query: GET_DATA, variables: DEFAULT_VARIABLES},
      result: {data: {posts: [{id: '1', title: 'Newest Post', content: 'content', imageUrl: null, commentCounter: 0}]}},
    };
    const oldestMock = {
      request: {query: GET_DATA, variables: {...DEFAULT_VARIABLES, sortBy: 'OLDEST'}},
      result: {data: {posts: [{id: '2', title: 'Oldest Post', content: 'content', imageUrl: null, commentCounter: 0}]}},
    };

    render(
      <MockedProvider mocks={[newestMock, oldestMock]} addTypename={false}>
        <PostsPage />
      </MockedProvider>,
    );

    await waitFor(() => expect(screen.getByText('Newest Post')).toBeDefined());

    fireEvent.mouseDown(screen.getByRole('combobox', {name: /sort posts by/i}));
    fireEvent.click(screen.getByText('Oldest first'));

    await waitFor(() => expect(screen.getByText('Oldest Post')).toBeDefined());
  });
});
