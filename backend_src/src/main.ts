import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';
import * as compression from 'compression';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    // Structured, no-secrets-by-default logging. Individual services
    // are responsible for never logging passwords/tokens/wardrobe
    // content (see AuthService.audit() — metadata only, never raw
    // credentials or tokens).
    logger: ['log', 'warn', 'error'],
  });

  app.use(helmet());
  app.use(compression());

  // CORS: origin is environment-driven so production can lock this
  // down to the real Stylish web/app origins instead of "*".
  const corsOrigin = process.env.CORS_ORIGIN || '*';
  app.enableCors({
    origin: corsOrigin === '*' ? true : corsOrigin.split(','),
    credentials: true,
  });

  // Global validation: every DTO's class-validator decorators are now
  // actually enforced. whitelist+forbidNonWhitelisted rejects any
  // unexpected/extra body fields (defense against mass-assignment).
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  app.setGlobalPrefix('api');

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`Stylish backend listening on port ${port} (env: ${process.env.NODE_ENV ?? 'development'})`);
}
bootstrap();
