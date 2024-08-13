import '@credbull/contracts';
import {
  BadRequestException,
  Body,
  ConsoleLogger,
  Controller,
  Get,
  InternalServerErrorException,
  NotFoundException,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiResponse, ApiTags } from '@nestjs/swagger';

import { SupabaseGuard, SupabaseRoles } from '../../clients/supabase/auth/supabase.guard';
import { isKnownError } from '../../utils/errors';
import { CronGuard } from '../../utils/guards';

import { EntitiesDto } from './entities.dto';
import { MatureVaultsService } from './mature-vaults.service';
import { UpsideVaultParamsDto, VaultParamsDto, VaultsDto } from './vaults.dto';
import { VaultsService } from './vaults.service';

@Controller('vaults')
@ApiTags('Vaults')
@ApiBearerAuth()
export class VaultsController {
  constructor(
    private readonly vaults: VaultsService,
    private readonly mature: MatureVaultsService,
    private readonly logger: ConsoleLogger,
  ) {
    this.logger.setContext(VaultsController.name);
  }

  @Get('/current')
  @UseGuards(SupabaseGuard)
  @ApiOperation({ summary: 'Returns current active and matured vaults' })
  @ApiResponse({ status: 200, description: 'Success', type: VaultsDto })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async current(): Promise<VaultsDto> {
    const { data, error } = await this.vaults.current();

    if (error) throw new InternalServerErrorException(error);
    if (!data) throw new NotFoundException();

    return new VaultsDto({ data });
  }

  @Post('/mature-outstanding')
  @UseGuards(CronGuard)
  @ApiOperation({ summary: 'Matures any outstanding vault and returns them' })
  @ApiResponse({ status: 200, description: 'Success', type: VaultsDto })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async matureOutstanding(): Promise<VaultsDto> {
    const { data, error } = await this.mature.matureOutstanding();

    if (isKnownError(error)) throw new BadRequestException(error);
    if (error) throw new InternalServerErrorException(error);
    if (!data) throw new NotFoundException();

    return new VaultsDto({ data });
  }

  @Post('/create-vault')
  @SupabaseRoles(['admin'])
  @ApiOperation({ summary: 'Create a new vault' })
  @ApiResponse({ status: 200, description: 'Success', type: VaultsDto })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async createVault(@Body() dto: VaultParamsDto): Promise<VaultsDto> {
    const { data, error } = await this.vaults.createVault(dto);

    if (isKnownError(error)) throw new BadRequestException(error);
    if (error) throw new InternalServerErrorException(error);
    if (!data) throw new NotFoundException();

    return new VaultsDto({ data: [data] });
  }

  @Get('/vault-entities/:id')
  @UseGuards(SupabaseGuard)
  @ApiParam({ name: 'id', required: true, type: String })
  @ApiOperation({ summary: 'Get entities detail of a vault' })
  @ApiResponse({ status: 200, description: 'Success', type: EntitiesDto })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async vaultEntities(@Param('id') id: string): Promise<EntitiesDto> {
    const { data, error } = await this.vaults.vaultEntities(Number(id));

    if (error) throw new InternalServerErrorException(error);
    if (!data) throw new NotFoundException();

    return new EntitiesDto({ data });
  }

  @Post('/create-vault-upside')
  @SupabaseRoles(['admin'])
  @ApiOperation({ summary: 'Create a new vault' })
  @ApiResponse({ status: 200, description: 'Success', type: VaultsDto })
  @ApiResponse({ status: 400, description: 'Bad Request' })
  @ApiResponse({ status: 500, description: 'Internal Error' })
  async createVaultUpside(@Body() dto: UpsideVaultParamsDto): Promise<VaultsDto> {
    const { data, error } = await this.vaults.createVault(dto as VaultParamsDto, true, dto.upsidePercentage);

    if (isKnownError(error)) throw new BadRequestException(error);
    if (error) throw new InternalServerErrorException(error);
    if (!data) throw new NotFoundException();

    return new VaultsDto({ data: [data] });
  }
}
