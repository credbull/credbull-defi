import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { MetaTxService } from './metatx.service';

@Controller('metatx')
@ApiTags('Transactions')
export class MetaTxController {
  constructor(private readonly metaTx: MetaTxService) {}

  @Get()
  async getData(): Promise<string> {
    return this.metaTx.getData();
  }
}
