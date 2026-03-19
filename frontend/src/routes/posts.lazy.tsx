import {useQuery} from '@apollo/client';
import {CircularProgress, Container, Stack, Typography} from '@mui/material';
import {createLazyFileRoute} from '@tanstack/react-router';
import {PostCard} from '../components/PostCard';
import {GET_DATA} from '../queries/get_posts';

export const Route = createLazyFileRoute('/posts')({
  component: PostsPage,
});

function PostsPage() {
  const {data, loading, error} = useQuery(GET_DATA);

  return (
    <Container>
      <Typography variant="h4" marginY={2}>
        Posts
      </Typography>
      {loading && <CircularProgress />}
      {error && (
        <Typography color="error">
          Failed to load posts: {error.message}
        </Typography>
      )}
      <Stack direction="row" flexWrap="wrap" gap={2}>
        {data?.posts.map((post: {id: string; title: string; imageUrl?: string | null; commentCounter: number}) => (
          <PostCard key={post.id} title={post.title} imageUrl={post.imageUrl} commentCounter={post.commentCounter} />
        ))}
      </Stack>
    </Container>
  );
}
