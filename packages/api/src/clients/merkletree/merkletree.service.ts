import { Injectable } from '@nestjs/common';
import { keccak256 } from 'ethers/lib/utils';
import MerkleTree from 'merkletreejs';

import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class MerkleTreeService {
  constructor(private supabase: SupabaseService) {}

  async addLeaves(addresses: string[]): Promise<string> {
    const leaves = addresses.map((addr) => this.padBuffer(addr));
    const tree = await this.loadTree();
    tree.addLeaves(leaves);

    return tree.getHexRoot();
  }

  async getProof(address: string): Promise<string[]> {
    return (await this.loadTree()).getHexProof(this.padBuffer(address));
  }

  async getRoot(): Promise<string> {
    return (await this.loadTree()).getHexRoot();
  }

  padBuffer(addr: string): Buffer {
    return Buffer.from(addr, 'hex');
  }

  async loadTree(): Promise<MerkleTree> {
    const client = this.supabase.admin();
    const { data } = await client.from('kyc_events').select();

    let leaves: Buffer[] = [];

    if (data && data.length > 0) {
      leaves = data.map((userData) => this.padBuffer(userData.address));
    }

    return new MerkleTree(leaves, keccak256, { sortPairs: true });
  }
}
