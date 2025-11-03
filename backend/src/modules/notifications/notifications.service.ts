import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
import * as admin from 'firebase-admin';
import { getFirebaseApp } from '../../config/firebase.config';
import { Notification } from './entities/notification.entity';
import { NotificationJob, JobStatus } from './entities/notification-job.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class NotificationsService {
  private firebaseApp: admin.app.App;

  constructor(
    @InjectRepository(Notification)
    private notificationRepository: Repository<Notification>,
    @InjectRepository(NotificationJob)
    private jobRepository: Repository<NotificationJob>,
    private usersService: UsersService,
  ) {
    this.firebaseApp = getFirebaseApp();
  }

  async createNotification(
    userId: string,
    title: string,
    body: string,
    metadata?: Record<string, any>,
  ) {
    const notification = this.notificationRepository.create({
      userId,
      title,
      body,
      metadata,
      isRead: false,
      isDeleted: false,
      sent: false,
    });

    const saved = await this.notificationRepository.save(notification);

    const job = this.jobRepository.create({
      notificationId: saved.id,
      status: JobStatus.PENDING,
      retries: 0,
    });
    await this.jobRepository.save(job);

    return saved;
  }

  async getUserNotifications(userId: string, limit: number = 50, since?: Date) {
    const where: any = { userId, isDeleted: false };
    if (since) {
      where.receivedAt = MoreThan(since);
    }

    return this.notificationRepository.find({
      where,
      order: { receivedAt: 'DESC' },
      take: limit,
    });
  }

  async markAsRead(userId: string, notificationIds: string[]) {
    await this.notificationRepository.update(
      { id: { $in: notificationIds } as any, userId },
      { isRead: true },
    );
    return { success: true };
  }

  async deleteNotification(userId: string, notificationId: string) {
    const notification = await this.notificationRepository.findOne({
      where: { id: notificationId, userId },
    });

    if (!notification) {
      throw new Error('Notification not found');
    }

    notification.isDeleted = true;
    await this.notificationRepository.save(notification);
    return { success: true };
  }

  async sendTestPush(userId: string, title: string, body: string) {
    console.log(`🔔 Test push requested for user: ${userId}, title: ${title}`);
    
    try {
      const tokens = await this.usersService.getUserTokens(userId);
      console.log(`📱 Found ${tokens.length} FCM token(s) for user`);

      if (tokens.length === 0) {
        throw new Error('No FCM tokens registered for this user. Please make sure you are logged in on a device.');
      }

      // Create notification record
      const notification = await this.createNotification(userId, title, body, { type: 'test' });
      console.log(`📝 Notification created with ID: ${notification.id}`);

      // Send immediately for test push (don't wait for worker)
      const tokenStrings = tokens.map((t) => t.token);
      
      console.log(`🔥 Firebase App initialized: ${!!this.firebaseApp}`);
      
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          notificationId: notification.id,
          type: 'test',
        },
        tokens: tokenStrings,
      };

      console.log(`🚀 Sending FCM message to ${tokenStrings.length} device(s)...`);
      console.log(`📦 Message payload:`, JSON.stringify(message, null, 2));
      
      const response = await admin.messaging(this.firebaseApp).sendEachForMulticast(message);
      
      console.log(`✅ FCM Response - Success: ${response.successCount}, Failures: ${response.failureCount}`);
      
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.error(`❌ Failed to send to token ${idx}: ${resp.error?.message}`);
            console.error(`❌ Error code: ${resp.error?.code}`);
          }
        });
      }

      // Mark notification as sent
      notification.sent = true;
      await this.notificationRepository.save(notification);

      // Update the job status to completed
      const jobs = await this.jobRepository.find({
        where: { notification: { id: notification.id } },
      });
      
      for (const job of jobs) {
        job.status = JobStatus.COMPLETED;
        job.messageId = response.responses[0]?.messageId || 'sent';
        await this.jobRepository.save(job);
      }

      return {
        success: true,
        notificationId: notification.id,
        successCount: response.successCount,
        failureCount: response.failureCount,
        message: `Test push sent successfully to ${response.successCount} device(s)`,
      };
    } catch (error: any) {
      console.error(`❌ ERROR in sendTestPush:`, error);
      console.error(`❌ Error stack:`, error.stack);
      console.error(`❌ Error name:`, error.name);
      console.error(`❌ Error message:`, error.message);
      throw new Error(`Failed to send push notification: ${error.message}`);
    }
  }

  async processPendingJobs(limit: number = 10) {
    const jobs = await this.jobRepository.find({
      where: { status: JobStatus.PENDING },
      relations: ['notification', 'notification.user'],
      take: limit,
      order: { createdAt: 'ASC' },
    });

    const maxRetries = parseInt(process.env.MAX_NOTIFICATION_RETRIES || '5', 10);

    for (const job of jobs) {
      job.status = JobStatus.PROCESSING;
      job.processingAt = new Date();
      await this.jobRepository.save(job);

      try {
        const tokens = await this.usersService.getUserTokens(job.notification.userId);
        const tokenStrings = tokens.map((t) => t.token);

        if (tokenStrings.length === 0) {
          job.status = JobStatus.FAILED;
          job.lastError = 'No FCM tokens found';
          await this.jobRepository.save(job);
          continue;
        }

        const message = {
          notification: {
            title: job.notification.title,
            body: job.notification.body,
          },
          data: {
            notificationId: job.notification.id,
            ...(job.notification.metadata || {}),
          },
          tokens: tokenStrings,
        };

        const response = await admin.messaging(this.firebaseApp).sendEachForMulticast(message);

        job.notification.sent = true;
        await this.notificationRepository.save(job.notification);

        job.status = JobStatus.COMPLETED;
        job.messageId = response.responses[0]?.messageId || 'sent';
        await this.jobRepository.save(job);
      } catch (error: any) {
        job.retries += 1;
        job.lastError = error.message;

        if (job.retries >= maxRetries) {
          job.status = JobStatus.DEAD_LETTER;
        } else {
          job.status = JobStatus.PENDING;
        }
        await this.jobRepository.save(job);
      }
    }

    return { processed: jobs.length };
  }
}
