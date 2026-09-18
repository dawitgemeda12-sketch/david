import { IsString, MinLength } from 'class-validator';

/**
 * Google Sign-In DTO: the Flutter client sends the ID token obtained
 * from the native Google Sign-In SDK. The backend verifies this token
 * server-side against Google's public keys (google-auth-library) —
 * the client NEVER sends a client secret, and the backend NEVER
 * trusts a client-supplied email/name without verifying the token.
 *
 * Requires GOOGLE_CLIENT_ID configured in the backend environment to
 * activate (see .env.example). Until configured, this endpoint returns
 * 501 Not Implemented rather than pretending to work.
 */
export class GoogleLoginDto {
  @IsString()
  @MinLength(10)
  idToken: string;
}
