import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Applied to every protected route. Rejects requests without a valid,
 * non-expired access token before any controller code runs.
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
