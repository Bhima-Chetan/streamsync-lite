import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';
import { VideosService } from './videos.service';
import { VideosController } from './videos.controller';
import { Video } from './entities/video.entity';
import { Progress } from './entities/progress.entity';
import { Favorite } from './entities/favorite.entity';
import { YoutubeService } from './youtube.service';

@Module({
  imports: [TypeOrmModule.forFeature([Video, Progress, Favorite]), HttpModule],
  providers: [VideosService, YoutubeService],
  controllers: [VideosController],
  exports: [VideosService],
})
export class VideosModule {}
