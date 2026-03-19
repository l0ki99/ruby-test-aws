import {Card, CardContent, CardMedia, Typography} from '@mui/material';

interface PostCardProps {
  title: string;
  imageUrl?: string | null;
}

export function PostCard({title, imageUrl}: PostCardProps) {
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
        <Typography variant="subtitle1" fontWeight="bold">
          {title}
        </Typography>
      </CardContent>
    </Card>
  );
}
