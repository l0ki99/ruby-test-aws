import {Card, CardContent, CardMedia, Typography} from '@mui/material';

interface PostCardProps {
  title: string;
}

export function PostCard({title}: PostCardProps) {
  return (
    <Card sx={{width: 300}}>
      <CardMedia
        sx={{
          height: 300,
          backgroundColor: '#000',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
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
