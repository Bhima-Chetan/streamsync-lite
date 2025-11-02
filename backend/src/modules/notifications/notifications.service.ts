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
    const tokens = await this.usersService.getUserTokens(userId);

    if (tokens.length === 0) {
      throw new Error('No FCM tokens registered for this user');
    }

    const notification = await this.createNotification(userId, title, body, { type: 'test' });

    return {
      success: true,
      notificationId: notification.id,
      message: `Test push queued for ${tokens.length} device(s)`,
    };
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
