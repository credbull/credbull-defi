import { ApiProperty } from '@nestjs/swagger';
import { Session } from '@supabase/supabase-js';
import { IsString } from 'class-validator';

export class CreateAccessTokenDto {
  @IsString()
  @ApiProperty({
    description: 'refresh token',
  })
  refreshToken: string;

  constructor(partial: Partial<CreateAccessTokenDto>) {
    Object.assign(this, partial);
  }
}

export class RefreshTokenDto {
  @IsString()
  @ApiProperty({
    description: 'refresh token',
  })
  refreshToken: string;

  @IsString()
  @ApiProperty({
    description: 'access token',
  })
  accessToken: string;

  constructor(partial: Pick<Session, 'refresh_token' | 'access_token'>) {
    this.accessToken = partial.access_token;
    this.refreshToken = partial.refresh_token;
  }
}
