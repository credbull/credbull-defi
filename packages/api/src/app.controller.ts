import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { TomlConfigService } from './utils/config';

@Controller()
@ApiTags('Version')
export class AppController {
  constructor(private readonly tomlConfigService: TomlConfigService) {}

  @Get()
  @ApiOperation({ summary: 'Returns the api version' })
  @ApiResponse({ status: 200, description: 'Success', type: String })
  version(): string {
    return this.tomlConfigService.getConfig.api.version;
  }
}
