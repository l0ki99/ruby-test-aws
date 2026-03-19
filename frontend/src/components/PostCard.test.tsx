import {render, screen, fireEvent} from '@testing-library/react';
import {describe, it, expect, vi, afterEach} from 'vitest';
import {PostCard} from './PostCard';

describe('PostCard', () => {
  it('renders the post title', () => {
    render(<PostCard title="My Test Post" commentCounter={0} />);
    expect(screen.getByText('My Test Post')).toBeDefined();
  });

  it('renders without crashing when no imageUrl is provided', () => {
    const {container} = render(<PostCard title="Test" commentCounter={0} />);
    expect(container.firstChild).toBeDefined();
  });
});

describe('PostCard image URL', () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it('shows the fallback image when imageUrl is null', () => {
    vi.stubEnv('VITE_API_BASE_URL', 'http://test-api:8090');
    render(<PostCard title="Test" imageUrl={null} commentCounter={0} />);
    expect(screen.getByRole('img').getAttribute('src')).toBe('http://test-api:8090/oops.png');
  });

  it('prepends VITE_API_BASE_URL for relative imageUrl', () => {
    vi.stubEnv('VITE_API_BASE_URL', 'http://test-api:8090');
    render(<PostCard title="Test" imageUrl="/cat.png" commentCounter={0} />);
    expect(screen.getByRole('img').getAttribute('src')).toBe('http://test-api:8090/cat.png');
  });

  it('uses an absolute imageUrl directly without modification', () => {
    render(<PostCard title="Test" imageUrl="https://example.com/image.jpg" commentCounter={0} />);
    expect(screen.getByRole('img').getAttribute('src')).toBe('https://example.com/image.jpg');
  });

  it('falls back to oops.png when the image fails to load', () => {
    vi.stubEnv('VITE_API_BASE_URL', 'http://test-api:8090');
    render(<PostCard title="Test" imageUrl="/missing.png" commentCounter={0} />);
    fireEvent.error(screen.getByRole('img'));
    expect(screen.getByRole('img').getAttribute('src')).toBe('http://test-api:8090/oops.png');
  });
});
