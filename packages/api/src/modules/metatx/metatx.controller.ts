import { Controller, Get } from '@nestjs/common';

import { MetaTxService } from './metatx.service';

@Controller('metatx')
export class MetaTxController {
  constructor(private readonly metaTx: MetaTxService) {}

  @Get()
  async getData(): Promise<string> {
    return this.metaTx.getData();
  }
}
