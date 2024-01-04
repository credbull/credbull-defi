import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseGuard, SupabaseRoles } from '../../clients/supabase/auth/supabase.guard';

import { AccountStatusDto, KYCStatus } from './account-status.dto';
import { KycService } from './kyc.service';
import { WhitelistAccountDto } from './whitelist-account.dto';

@Controller('accounts')
@ApiBearerAuth()
@UseGuards(SupabaseGuard)
@ApiTags('Accounts')
export class AccountsController {
  constructor(private readonly kyc: KycService) {}

  @Get('status')
  @ApiOperation({ summary: 'Returns users account status' })
  @ApiResponse({ status: 200, description: 'Success', type: AccountStatusDto })
  async status(): Promise<AccountStatusDto> {
    const status = await this.kyc.status();

    return new AccountStatusDto({ status });
  }

  @Post('whitelist')
  @SupabaseRoles(['admin'])
  @ApiOperation({ summary: 'Whitelists a give address' })
  @ApiResponse({ status: 400, description: 'Incorrect user data' })
  @ApiResponse({ status: 200, description: 'Success', type: AccountStatusDto })
  async whitelist(@Body() data: WhitelistAccountDto): Promise<AccountStatusDto> {
    const success = await this.kyc.whitelist(data.address);

    return new AccountStatusDto({ status: success ? KYCStatus.ACTIVE : KYCStatus.REJECTED });
  }
}
