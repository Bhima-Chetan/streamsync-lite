import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

@Entity('videos')
export class Video {
  @PrimaryColumn({ name: 'video_id' })
  videoId: string;

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ name: 'thumbnail_url' })
  thumbnailUrl: string;

  @Column({ name: 'channel_id' })
  @Index()
  channelId: string;

  @Column({ name: 'channel_title' })
  channelTitle: string;

  @Column({ name: 'published_at', type: 'timestamp' })
  publishedAt: Date;

  @Column({ name: 'duration_seconds', type: 'int' })
  durationSeconds: number;

  @Column({ name: 'view_count', type: 'bigint', nullable: true })
  viewCount: number;

  @Column({ name: 'like_count', type: 'bigint', nullable: true })
  likeCount: number;

  @Column({ name: 'comment_count', type: 'bigint', nullable: true })
  commentCount: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
