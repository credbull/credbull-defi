import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

@Controller()
@ApiBearerAuth()
@ApiTags('Version')
export class AppController {
  constructor(private readonly config: ConfigService) {}

  @Get()
  @ApiOperation({ summary: 'Returns the api version' })
  @ApiResponse({ status: 200, description: 'Success', type: String })
  version(): string {
    return this.config.getOrThrow('APP_VERSION');
  }
}
