import { Module } from '@nestjs/common';

import { MetaTxController } from './metatx.controller';
import { MetaTxService } from './metatx.service';

@Module({
  controllers: [MetaTxController],
  providers: [MetaTxService],
})
export class MetaTxModule {}
