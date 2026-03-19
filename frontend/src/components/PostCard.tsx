import {Card, CardContent, CardMedia, Typography} from '@mui/material';

interface PostCardProps {
  title: string;
  imageUrl?: string | null;
  commentCounter: number;
}

export function PostCard({title, imageUrl, commentCounter}: PostCardProps) {
  return (
    <Card sx={{width: 300}}>
      <CardMedia
        component="img"
        height={300}
        image={imageUrl ? (imageUrl.startsWith('/') ? `${import.meta.env.VITE_API_BASE_URL}${imageUrl}` : imageUrl) : undefined}
        sx={{
          backgroundColor: '#000',
          objectFit: 'cover',
        }}
      />
      <CardContent>
        <Typography variant="subtitle1" fontWeight="bold" display="flex" justifyContent="space-between">
          <span>{title}</span>
          <span>({commentCounter})</span>
        </Typography>
      </CardContent>
    </Card>
  );
}
