import { BadRequestException, Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseService } from '../../clients/supabase/supabase.service';

import { AccountStatusDto } from './account-status.dto';
import { KycService } from './kyc.service';

@Controller('accounts')
@ApiBearerAuth()
@ApiTags('Accounts')
export class AccountsController {
  constructor(
    private readonly kyc: KycService,
    private readonly supabase: SupabaseService,
  ) {}

  @Get('status')
  @ApiOperation({ summary: 'Returns users account status' })
  @ApiResponse({ status: 400, description: 'Bad Request: no user wallet' })
  @ApiResponse({ status: 200, description: 'Success', type: AccountStatusDto })
  async status(): Promise<AccountStatusDto> {
    const { data } = await this.supabase.client().from('user_wallets').select().single();
    if (!data?.address) throw new BadRequestException();

    const status = await this.kyc.status(data.address);
    return new AccountStatusDto({ status });
  }
}
