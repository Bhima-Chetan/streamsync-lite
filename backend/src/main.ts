import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import helmet from 'helmet';
import { Logger } from 'nestjs-pino';
import { initializeFirebase } from './config/firebase.config';
import { loadParametersFromSSM } from './config/parameter-store.config';

async function bootstrap() {
  // Load parameters from AWS Systems Manager Parameter Store (production only)
  if (process.env.NODE_ENV === 'production' || process.env.USE_SSM === 'true') {
    try {
      await loadParametersFromSSM();
    } catch (error) {
      console.error('❌ Failed to load parameters from SSM, using .env fallback:', error);
    }
  }

  // Initialize Firebase Admin SDK
  try {
    initializeFirebase();
    console.log('✅ Firebase Admin SDK initialized successfully');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error);
  }

  const app = await NestFactory.create(AppModule, { bufferLogs: true });

  app.useLogger(app.get(Logger));
  app.use(helmet());
  app.enableCors();

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('StreamSync Lite API')
    .setDescription('Mobile learning video app API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Application is running on: http://localhost:${port}`);
  console.log(`API Documentation: http://localhost:${port}/api/docs`);
}
bootstrap();
