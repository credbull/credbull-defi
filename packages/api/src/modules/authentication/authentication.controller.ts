import { BadRequestException, Body, Controller, InternalServerErrorException, Post } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseService } from '../../clients/supabase/supabase.service';

import { CreateAccessTokenDto, RefreshTokenDto } from './refresh-token.dto';

@Controller('auth')
@ApiTags('authentication')
export class AuthenticationController {
  constructor(private readonly supabase: SupabaseService) {}

  @Post('token')
  @ApiOperation({ summary: 'Returns a new access token and refresh token' })
  @ApiResponse({ status: 200, description: 'Success' })
  async refreshToken(@Body() data: CreateAccessTokenDto): Promise<RefreshTokenDto> {
    const { data: auth, error } = await this.supabase.admin().auth.refreshSession({ refresh_token: data.refreshToken });

    if (error) throw new BadRequestException(error);
    if (!auth.session) throw new InternalServerErrorException("Couldn't refresh session");

    return new RefreshTokenDto(auth.session);
  }
}
