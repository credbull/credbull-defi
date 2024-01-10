import { BadRequestException, Body, Controller, Get, NotFoundException, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseGuard, SupabaseRoles } from '../../clients/supabase/auth/supabase.guard';
import { UserWalletDto } from '../../types/db.dto';

import { AccountStatusDto } from './accounts.dto';
import { KYCStatus, WhitelistAccountDto } from './kyc.dto';
import { KycService } from './kyc.service';
import { WalletDto } from './wallets.dto';
import { WalletsService } from './wallets.service';

@Controller('accounts')
@ApiBearerAuth()
@UseGuards(SupabaseGuard)
@ApiTags('Accounts')
export class AccountsController {
  constructor(
    private readonly kyc: KycService,
    private readonly wallets: WalletsService,
  ) {}

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

  @Post('link-wallet')
  @ApiOperation({ summary: 'Links a wallet with a user' })
  @ApiResponse({ status: 200, description: 'Success', type: UserWalletDto })
  async linkWallet(@Body() dto: WalletDto): Promise<UserWalletDto> {
    const { error, data } = await this.wallets.link(dto);

    if (error) throw new BadRequestException(error);
    if (!data) throw new NotFoundException();

    return new UserWalletDto(data);
  }
}
