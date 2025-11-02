import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { FcmToken } from './entities/fcm-token.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(FcmToken)
    private fcmTokenRepository: Repository<FcmToken>,
  ) {}

  async create(data: { email: string; name: string; passwordHash: string }) {
    const user = this.userRepository.create(data);
    return this.userRepository.save(user);
  }

  async findByEmail(email: string) {
    return this.userRepository.findOne({ where: { email } });
  }

  async findById(id: string) {
    return this.userRepository.findOne({ where: { id } });
  }

  async updateProfile(userId: string, data: { name?: string; email?: string }) {
    const user = await this.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    if (data.name !== undefined) {
      user.name = data.name;
    }
    if (data.email !== undefined) {
      user.email = data.email;
    }

    return this.userRepository.save(user);
  }

  async registerFcmToken(userId: string, token: string, platform: string = 'android') {
    const existing = await this.fcmTokenRepository.findOne({
      where: { userId, token },
    });

    if (existing) {
      return existing;
    }

    const fcmToken = this.fcmTokenRepository.create({
      userId,
      token,
      platform,
    });
    return this.fcmTokenRepository.save(fcmToken);
  }

  async removeFcmToken(userId: string, token: string) {
    await this.fcmTokenRepository.delete({ userId, token });
  }

  async getUserTokens(userId: string) {
    return this.fcmTokenRepository.find({ where: { userId } });
  }
}
