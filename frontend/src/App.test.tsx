import {render, screen} from '@testing-library/react';
import {describe, it, expect} from 'vitest';
import App, {GET_DATA} from './App';
import React from 'react';
import {ApolloClient, InMemoryCache, ApolloProvider} from '@apollo/client';
import {MockedProvider} from '@apollo/client/testing';

const client = new ApolloClient({
  cache: new InMemoryCache(),
  uri: 'http://localhost:4000/graphql', // Replace with your GraphQL endpoint
});

export const renderWithApollo = (ui: React.ReactElement) => {
  return render(<ApolloProvider client={client}>{ui}</ApolloProvider>);
};

export const renderWithMockedProvider = (
  ui: React.ReactElement,
  mocks: any[],
) => {
  return render(
    <MockedProvider mocks={mocks} addTypename={false}>
      {ui}
    </MockedProvider>,
  );
};

const mocks = [
  {
    request: {
      query: GET_DATA,
    },
    result: {
      data: {
        posts: [
          {id: 1, title: 'Post 1'},
          {id: 2, title: 'Post 2'},
        ],
      },
    },
  },
];
describe('App Component', () => {
  it('renders the Take-Home Assessment title', () => {
    renderWithMockedProvider(<App />, mocks);
    const titleElement = screen.getByText(/Take-Home Assessment/i);
    expect(titleElement).toBeDefined();
  });

  it('renders the Tech Stack section', () => {
    renderWithMockedProvider(<App />, mocks);
    const techStackElement = screen.getByText(/Tech Stack/i);
    expect(techStackElement).toBeDefined();
  });

  it('renders the list items', () => {
    renderWithMockedProvider(<App />, mocks);
    const listItemElements = screen.getAllByRole('listitem');
    expect(listItemElements.length).toBeGreaterThan(0);
  });
});
