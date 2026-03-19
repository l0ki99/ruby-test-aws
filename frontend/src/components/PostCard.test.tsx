import {render, screen, fireEvent} from '@testing-library/react';
import {describe, it, expect, vi, afterEach} from 'vitest';
import {PostCard} from './PostCard';

const CONTENT_PREVIEW_LENGTH = 50;

describe('PostCard', () => {
  it('renders the post title', () => {
    render(<PostCard title="My Test Post" content="" commentCounter={0} />);
    expect(screen.getByText('My Test Post')).toBeDefined();
  });

  it('renders without crashing when no imageUrl is provided', () => {
    const {container} = render(<PostCard title="Test" content="" commentCounter={0} />);
    expect(container.firstChild).toBeDefined();
  });
});

describe('PostCard content preview', () => {
  it('displays the first 50 characters of content', () => {
    render(<PostCard title="Test" content="Hello world" commentCounter={0} />);
    expect(screen.getByText('Hello world')).toBeDefined();
  });

  it('displays content exactly 50 characters without ellipsis', () => {
    const exact = 'A'.repeat(CONTENT_PREVIEW_LENGTH);
    render(<PostCard title="Test" content={exact} commentCounter={0} />);
    expect(screen.getByText(exact)).toBeDefined();
  });

  it('truncates content longer than 50 characters and appends ellipsis', () => {
    const long = 'A'.repeat(CONTENT_PREVIEW_LENGTH + 10);
    render(<PostCard title="Test" content={long} commentCounter={0} />);
    expect(screen.getByText(`${'A'.repeat(CONTENT_PREVIEW_LENGTH)}...`)).toBeDefined();
  });
});

describe('PostCard comment counter', () => {
  it('displays the comment count next to the title', () => {
    render(<PostCard title="Test" content="" commentCounter={5} />);
    expect(screen.getByText('(5)')).toBeDefined();
  });

  it('displays (0) when there are no comments', () => {
    render(<PostCard title="Test" content="" commentCounter={0} />);
    expect(screen.getByText('(0)')).toBeDefined();
  });
});

describe('PostCard image URL', () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it('shows the fallback image when imageUrl is null', () => {
    vi.stubEnv('VITE_API_BASE_URL', 'http://test-api:8090');
    render(<PostCard title="Test" content="" imageUrl={null} commentCounter={0} />);
    expect(screen.getByRole('img').getAttribute('src')).toBe('http://test-api:8090/oops.png');
  });

  it('prepends VITE_API_BASE_URL for relative imageUrl', () => {
    vi.stubEnv('VITE_API_BASE_URL', 'http://test-api:8090');
    render(<PostCard title="Test" content="" imageUrl="/cat.png" commentCounter={0} />);
    expect(screen.getByRole('img').getAttribute('src')).toBe('http://test-api:8090/cat.png');
  });

  it('uses an absolute imageUrl directly without modification', () => {
    render(<PostCard title="Test" content="" imageUrl="https://example.com/image.jpg" commentCounter={0} />);
    expect(screen.getByRole('img').getAttribute('src')).toBe('https://example.com/image.jpg');
  });

  it('falls back to oops.png when the image fails to load', () => {
    vi.stubEnv('VITE_API_BASE_URL', 'http://test-api:8090');
    render(<PostCard title="Test" content="" imageUrl="/missing.png" commentCounter={0} />);
    fireEvent.error(screen.getByRole('img'));
    expect(screen.getByRole('img').getAttribute('src')).toBe('http://test-api:8090/oops.png');
  });
});
