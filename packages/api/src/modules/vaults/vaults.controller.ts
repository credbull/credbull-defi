import { BadRequestException, Controller, Get, NotFoundException, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseGuard } from '../../clients/supabase/auth/supabase.guard';

import { VaultsDto } from './vaults.dto';
import { VaultsService } from './vaults.service';

@Controller('vaults')
@ApiTags('Vaults')
@ApiBearerAuth()
@UseGuards(SupabaseGuard)
export class VaultsController {
  constructor(private readonly vaults: VaultsService) {}

  @Get('/current')
  @ApiOperation({ summary: 'Returns current open vaults' })
  @ApiResponse({
    status: 200,
    description: 'Success',
    type: VaultsDto,
  })
  async current(): Promise<VaultsDto> {
    const { data, error } = await this.vaults.current();

    if (error) throw new BadRequestException(error);
    if (!data) throw new NotFoundException();

    return new VaultsDto({ data });
  }
}
