import {useQuery} from '@apollo/client';
import {CircularProgress, Container, MenuItem, Select, SelectChangeEvent, Stack, Typography} from '@mui/material';
import {createLazyFileRoute} from '@tanstack/react-router';
import {useState} from 'react';
import {PostCard} from '../components/PostCard';
import {GET_DATA} from '../queries/get_posts';

export const Route = createLazyFileRoute('/posts')({
  component: PostsPage,
});

export const PAGE = 1;
export const PER_PAGE = 20;

const SORT_OPTIONS = [
  {value: 'NEWEST', label: 'Newest first'},
  {value: 'OLDEST', label: 'Oldest first'},
  {value: 'AUTHOR_AZ', label: 'Author (A–Z)'},
  {value: 'AUTHOR_ZA', label: 'Author (Z–A)'},
] as const;

export type SortOption = (typeof SORT_OPTIONS)[number]['value'];

export function PostsPage() {
  const [sortBy, setSortBy] = useState<SortOption>('NEWEST');

  const {data, loading, error} = useQuery(GET_DATA, {
    variables: {page: PAGE, perPage: PER_PAGE, sortBy},
  });

  function handleSortChange(event: SelectChangeEvent) {
    setSortBy(event.target.value as SortOption);
  }

  return (
    <Container>
      <Stack direction="row" alignItems="center" justifyContent="space-between" marginY={2}>
        <Typography variant="h4">Posts</Typography>
        <Select value={sortBy} onChange={handleSortChange} size="small" SelectDisplayProps={{'aria-label': 'Sort posts by'}}>
          {SORT_OPTIONS.map((opt) => (
            <MenuItem key={opt.value} value={opt.value}>
              {opt.label}
            </MenuItem>
          ))}
        </Select>
      </Stack>
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
