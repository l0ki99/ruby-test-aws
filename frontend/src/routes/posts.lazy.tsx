import {useQuery} from '@apollo/client';
import {CircularProgress, Container, Stack, Typography} from '@mui/material';
import {createLazyFileRoute} from '@tanstack/react-router';
import {PostCard} from '../components/PostCard';
import {GET_DATA} from '../queries/get_posts';

export const Route = createLazyFileRoute('/posts')({
  component: PostsPage,
});

export const PAGE = 1;
export const PER_PAGE = 20;

export function PostsPage() {
  const {data, loading, error} = useQuery(GET_DATA, {
    variables: {page: PAGE, perPage: PER_PAGE},
  });

  return (
    <Container>
      <Typography variant="h4" marginY={2}>
        Posts
      </Typography>
      {loading && <CircularProgress />}
      {error?.networkError && (
        <Typography color="error">
          Network error: unable to reach the server.
        </Typography>
      )}
      {error?.graphQLErrors?.map((e, i) => (
        <Typography key={i} color="error">
          {e.message}
        </Typography>
      ))}
      <Stack direction="row" flexWrap="wrap" gap={2}>
        {data?.posts.map((post: {id: string; title: string; content: string; imageUrl?: string | null; commentCounter: number}) => (
          <PostCard key={post.id} title={post.title} content={post.content} imageUrl={post.imageUrl} commentCounter={post.commentCounter} />
        ))}
      </Stack>
    </Container>
  );
}
