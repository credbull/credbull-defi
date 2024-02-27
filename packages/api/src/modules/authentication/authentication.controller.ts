import { Log } from '@algoan/nestjs-logging-interceptor';
import { BadRequestException, Body, Controller, InternalServerErrorException, Post } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseAdminService } from '../../clients/supabase/supabase-admin.service';
import { isKnownError } from '../../utils/errors';

import { CreateAccessTokenDto, RefreshTokenDto, SignInDto } from './authentication.dto';

@Controller('auth')
@ApiTags('Authentication')
export class AuthenticationController {
  constructor(private readonly supabase: SupabaseAdminService) {}

  @Post('api/sign-in')
  @Log({
    mask: { request: ['password'], response: ['refresh_token', 'access_token'] },
  })
  @ApiOperation({ summary: 'Returns a new access token and refresh token' })
  @ApiResponse({ status: 200, description: 'Success' })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async signIn(@Body() data: SignInDto): Promise<RefreshTokenDto> {
    const { data: auth, error } = await this.supabase.admin().auth.signInWithPassword(data);

    if (isKnownError(error)) throw new BadRequestException(error);
    if (error) throw new InternalServerErrorException(error);
    if (!auth.session) throw new InternalServerErrorException("Couldn't refresh session");

    return new RefreshTokenDto(auth.session);
  }

  @Post('api/token')
  @Log({
    mask: { request: ['refresh_token'], response: ['refresh_token', 'access_token'] },
  })
  @ApiOperation({ summary: 'Returns a new access token and refresh token' })
  @ApiResponse({ status: 200, description: 'Success' })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async refreshToken(@Body() data: CreateAccessTokenDto): Promise<RefreshTokenDto> {
    const { data: auth, error } = await this.supabase
      .admin()
      .auth.refreshSession({ refresh_token: data.refresh_token });

    if (isKnownError(error)) throw new BadRequestException(error);
    if (error) throw new InternalServerErrorException(error);
    if (!auth.session) throw new InternalServerErrorException("Couldn't refresh session");

    return new RefreshTokenDto(auth.session);
  }
}
