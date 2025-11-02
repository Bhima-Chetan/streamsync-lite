import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { NotificationsService } from './modules/notifications/notifications.service';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const notificationsService = app.get(NotificationsService);

  const pollInterval = parseInt(process.env.WORKER_POLL_INTERVAL || '5000', 10);

  console.log('Notification Worker Started');
  console.log(`Polling every ${pollInterval}ms`);

  setInterval(async () => {
    try {
      const result = await notificationsService.processPendingJobs(10);
      if (result.processed > 0) {
        console.log(`[${new Date().toISOString()}] Processed ${result.processed} jobs`);
      }
    } catch (error) {
      console.error('Worker error:', error);
    }
  }, pollInterval);
}

bootstrap();
