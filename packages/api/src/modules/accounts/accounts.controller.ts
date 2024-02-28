import {
  BadRequestException,
  Body,
  Controller,
  Get,
  InternalServerErrorException,
  NotFoundException,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseGuard, SupabaseRoles } from '../../clients/supabase/auth/supabase.guard';
import { UserWalletDto } from '../../types/db.dto';
import { isKnownError } from '../../utils/errors';

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
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async status(): Promise<AccountStatusDto> {
    const { data, error } = await this.kyc.status();

    if (isKnownError(error)) throw new BadRequestException(error);
    if (error) throw new InternalServerErrorException(error);
    if (!data) throw new NotFoundException();

    return new AccountStatusDto({ status: data });
  }

  @Post('whitelist')
  @SupabaseRoles(['admin'])
  @ApiOperation({ summary: 'Whitelists a give address' })
  @ApiResponse({ status: 200, description: 'Success', type: AccountStatusDto })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async whitelist(@Body() dto: WhitelistAccountDto): Promise<AccountStatusDto> {
    const { data, error } = await this.kyc.whitelist(dto);

    if (isKnownError(error)) throw new BadRequestException(error);
    if (error) throw new InternalServerErrorException(error);
    if (!data) throw new NotFoundException();

    return new AccountStatusDto({ status: KYCStatus.ACTIVE });
  }

  @Post('link-wallet')
  @ApiOperation({ summary: 'Links a wallet with a user' })
  @ApiResponse({ status: 200, description: 'Success', type: UserWalletDto })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async linkWallet(@Body() dto: WalletDto): Promise<UserWalletDto> {
    const { data, error } = await this.wallets.link(dto);

    if (isKnownError(error)) throw new BadRequestException(error);
    if (error) throw new InternalServerErrorException(error);
    if (!data) throw new NotFoundException();

    const [wallet] = data;
    return new UserWalletDto(wallet);
  }
}
