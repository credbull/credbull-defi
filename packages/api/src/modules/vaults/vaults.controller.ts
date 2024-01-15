import { BadRequestException, Controller, Get, NotFoundException, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseGuard } from '../../clients/supabase/auth/supabase.guard';
import { CronGuard } from '../../utils/guards';

import { VaultsDto } from './vaults.dto';
import { VaultsService } from './vaults.service';

@Controller('vaults')
@ApiTags('Vaults')
@ApiBearerAuth()
export class VaultsController {
  constructor(private readonly vaults: VaultsService) {}

  @Get('/current')
  @UseGuards(SupabaseGuard)
  @ApiOperation({ summary: 'Returns current active and matured vaults' })
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

  @Get('/mature-outstanding')
  @UseGuards(CronGuard)
  @ApiOperation({ summary: 'Matures any outstanding vault and returns them' })
  @ApiResponse({
    status: 200,
    description: 'Success',
    type: VaultsDto,
  })
  async matureOutstanding(): Promise<VaultsDto> {
    const { data, error } = await this.vaults.matureOutstanding();

    if (error) throw new BadRequestException(error);
    if (!data) throw new NotFoundException();

    return new VaultsDto({ data });
  }
}
