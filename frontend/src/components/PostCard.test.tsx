import {render, screen} from '@testing-library/react';
import {describe, it, expect} from 'vitest';
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
