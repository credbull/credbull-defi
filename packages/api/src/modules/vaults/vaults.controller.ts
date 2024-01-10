import { BadRequestException, Controller, Get, NotFoundException, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseGuard } from '../../clients/supabase/auth/supabase.guard';
import { SupabaseService } from '../../clients/supabase/supabase.service';

import { VaultsDto } from './vaults.dto';

@Controller('vaults')
@ApiTags('Vaults')
@ApiBearerAuth()
@UseGuards(SupabaseGuard)
export class VaultsController {
  constructor(private readonly supabase: SupabaseService) {}

  @Get('/current')
  @ApiOperation({ summary: 'Returns current open vaults' })
  @ApiResponse({ status: 200, description: 'Success', type: VaultsDto })
  async current(): Promise<VaultsDto> {
    const { data, error } = await this.supabase
      .client()
      .from('vaults')
      .select('*')
      .eq('status', 'ready')
      .lt('opened_at', 'now()')
      .gt('closed_at', 'now()');

    if (error) throw new BadRequestException(error);
    if (!data) throw new NotFoundException();

    return new VaultsDto({ data });
  }
}
