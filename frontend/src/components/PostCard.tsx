import React from 'react';
import {Card, CardContent, CardMedia, Typography} from '@mui/material';

const CARD_SIZE = 300;
const CONTENT_PREVIEW_LENGTH = 50;

interface PostCardProps {
  title: string;
  content: string;
  imageUrl?: string | null;
  commentCounter: number;
}

function fallbackImage(): string {
  return `${import.meta.env.VITE_API_BASE_URL}/oops.png`;
}

function resolveImageUrl(imageUrl?: string | null): string {
  if (!imageUrl) return fallbackImage();
  return imageUrl.startsWith('/') ? `${import.meta.env.VITE_API_BASE_URL}${imageUrl}` : imageUrl;
}

export function PostCard({title, content, imageUrl, commentCounter}: PostCardProps) {
  return (
    <Card sx={{width: CARD_SIZE}}>
      <CardMedia
        component="img"
        height={CARD_SIZE}
        image={resolveImageUrl(imageUrl)}
        onError={(e: React.SyntheticEvent<HTMLImageElement>) => {
          e.currentTarget.src = fallbackImage();
        }}
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
        <Typography variant="body2" color="text.secondary">
          {content.length > CONTENT_PREVIEW_LENGTH ? `${content.slice(0, CONTENT_PREVIEW_LENGTH)}...` : content}
        </Typography>
      </CardContent>
    </Card>
  );
}
