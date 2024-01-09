import { Injectable } from '@nestjs/common';

@Injectable()
export class MetaTxService {
  async getData(): Promise<string> {
    return 'Hello world';
  }
}
