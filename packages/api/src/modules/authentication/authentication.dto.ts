import { ApiProperty } from '@nestjs/swagger';
import { Session } from '@supabase/supabase-js';
import { IsString } from 'class-validator';

export class CreateAccessTokenDto {
  @IsString()
  @ApiProperty({ description: 'refresh token' })
  refresh_token: string;

  constructor(partial: Partial<CreateAccessTokenDto>) {
    Object.assign(this, partial);
  }
}

export class SignInDto {
  @IsString()
  @ApiProperty({ description: 'password' })
  password: string;

  @IsString()
  @ApiProperty({ description: 'email' })
  email: string;

  constructor(partial: Partial<SignInDto>) {
    Object.assign(this, partial);
  }
}

export class RefreshTokenDto {
  @IsString()
  @ApiProperty({ description: 'refresh token' })
  refresh_token: string;

  @IsString()
  @ApiProperty({ description: 'access token' })
  access_token: string;

  @IsString()
  @ApiProperty({ description: 'user_id' })
  user_id: string;

  constructor(partial: Pick<Session, 'refresh_token' | 'access_token' | 'user'>) {
    Object.assign(this, partial);
    this.user_id = partial.user.id;
  }
}
