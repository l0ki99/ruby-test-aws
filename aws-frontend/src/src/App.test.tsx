import {render, screen, waitFor} from '@testing-library/react';
import {describe, it, expect} from 'vitest';
import App from './App';
import {GET_DATA} from './queries/get_posts';
import React from 'react';
import {ApolloClient, InMemoryCache, ApolloProvider} from '@apollo/client';
import {MockedProvider, MockedResponse} from '@apollo/client/testing';

const client = new ApolloClient({
  cache: new InMemoryCache(),
  uri: 'http://localhost:4000/graphql', // Replace with your GraphQL endpoint
});

export const renderWithApollo = (ui: React.ReactElement) => {
  return render(<ApolloProvider client={client}>{ui}</ApolloProvider>);
};

export const renderWithMockedProvider = (
  ui: React.ReactElement,
  mocks: MockedResponse[],
) => {
  return render(
    <MockedProvider mocks={mocks} addTypename={false}>
      {ui}
    </MockedProvider>,
  );
};

const DEFAULT_MOCK_POSTS = [
  {id: 1, title: 'Post 1'},
  {id: 2, title: 'Post 2'},
];

const successMocks = [
  {
    request: {query: GET_DATA, variables: {}},
    result: {data: {posts: DEFAULT_MOCK_POSTS}},
  },
];

describe('App Component', () => {
  it('renders the Take-Home Assessment title', () => {
    renderWithMockedProvider(<App />, successMocks);
    const titleElement = screen.getByText(/Take-Home Assessment/i);
    expect(titleElement).toBeDefined();
  });

  it('renders the Tech Stack section', () => {
    renderWithMockedProvider(<App />, successMocks);
    const techStackElement = screen.getByText(/Tech Stack/i);
    expect(techStackElement).toBeDefined();
  });

  it('renders the list items', () => {
    renderWithMockedProvider(<App />, successMocks);
    const listItemElements = screen.getAllByRole('listitem');
    expect(listItemElements.length).toBeGreaterThan(0);
  });

  it('shows a network error message when the request fails', async () => {
    const mocks = [
      {
        request: {query: GET_DATA, variables: {}},
        error: new Error('Failed to fetch'),
      },
    ];
    renderWithMockedProvider(<App />, mocks);
    await waitFor(() => {
      expect(screen.getByText(/Network error: unable to reach the server/i)).toBeDefined();
    });
  });

  it('shows a GraphQL error message when the server returns an error', async () => {
    const mocks = [
      {
        request: {query: GET_DATA, variables: {}},
        result: {errors: [{message: 'Rate limit exceeded. Try again later.'}]},
      },
    ];
    renderWithMockedProvider(<App />, mocks);
    await waitFor(() => {
      expect(screen.getByText(/Rate limit exceeded/i)).toBeDefined();
    });
  });
});
