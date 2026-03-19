import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import client from './apollo-clients';
import {ApolloProvider} from '@apollo/client';
import {RouterProvider, createRouter} from '@tanstack/react-router';
// Import the generated route tree
import {routeTree} from './routeTree.gen';

// Create a new router instance
const router = createRouter({routeTree});

// Register the router instance for type safety
declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router;
  }
}
import '@fontsource/inter/300.css';
import '@fontsource/inter/400.css';
import '@fontsource/inter/500.css';
import '@fontsource/inter/700.css';
import {createTheme, ThemeProvider} from '@mui/material';

const theme = createTheme({
  typography: {
    fontFamily: 'Inter, Arial, sans-serif',
  },
});
createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ApolloProvider client={client}>
      <ThemeProvider theme={theme}>
        <RouterProvider router={router} />
      </ThemeProvider>
    </ApolloProvider>
  </StrictMode>,
);
