import { Injectable } from '@nestjs/common';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';

import { CustodianTransferDto } from './custodian.dto';

@Injectable()
export class CustodianService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
  ) {}

  async totalAssets(): Promise<ServiceResponse<number>> {
    // get final total returns from custodian (circle)
    return { data: 1200 };
  }

  async transfer(dto: CustodianTransferDto): Promise<ServiceResponse<CustodianTransferDto>> {
    // transfer funds from custodian to address
    return { data: dto };
  }
}
