import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';

/**
 * Restricts admin-only endpoints. Must be used AFTER JwtAuthGuard.
 * Ordinary users (isAdmin=false) receive a generic 403 — never a hint
 * about what the admin endpoint does.
 */
@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    if (!user?.isAdmin) {
      throw new ForbiddenException('You do not have permission to perform this action.');
    }
    return true;
  }
}
