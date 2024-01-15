export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export interface Database {
  public: {
    Tables: {
      kyc_events: {
        Row: {
          address: string;
          created_at: string;
          event_name: Database['public']['Enums']['kyc_event'];
          id: number;
          user_id: string;
        };
        Insert: {
          address: string;
          created_at?: string;
          event_name: Database['public']['Enums']['kyc_event'];
          id?: number;
          user_id: string;
        };
        Update: {
          address?: string;
          created_at?: string;
          event_name?: Database['public']['Enums']['kyc_event'];
          id?: number;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'kyc_events_user_id_fkey';
            columns: ['user_id'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
      user_wallets: {
        Row: {
          address: string;
          created_at: string;
          id: number;
          user_id: string;
        };
        Insert: {
          address: string;
          created_at?: string;
          id?: number;
          user_id: string;
        };
        Update: {
          address?: string;
          created_at?: string;
          id?: number;
          user_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'user_wallets_user_id_fkey';
            columns: ['user_id'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
      vault_distribution_configs: {
        Row: {
          created_at: string;
          entity_id: number;
          id: number;
          order: number;
          percentage: number;
        };
        Insert: {
          created_at?: string;
          entity_id: number;
          id?: number;
          order: number;
          percentage: number;
        };
        Update: {
          created_at?: string;
          entity_id?: number;
          id?: number;
          order?: number;
          percentage?: number;
        };
        Relationships: [
          {
            foreignKeyName: 'vault_distribution_configs_entity_id_fkey';
            columns: ['entity_id'];
            isOneToOne: false;
            referencedRelation: 'vault_distribution_entities';
            referencedColumns: ['id'];
          },
        ];
      };
      vault_distribution_entities: {
        Row: {
          address: string;
          created_at: string;
          id: number;
          type: Database['public']['Enums']['vault_distribution_entity_types'];
          vault_id: number;
        };
        Insert: {
          address: string;
          created_at?: string;
          id?: number;
          type: Database['public']['Enums']['vault_distribution_entity_types'];
          vault_id: number;
        };
        Update: {
          address?: string;
          created_at?: string;
          id?: number;
          type?: Database['public']['Enums']['vault_distribution_entity_types'];
          vault_id?: number;
        };
        Relationships: [
          {
            foreignKeyName: 'vault_distribution_entities_vault_id_fkey';
            columns: ['vault_id'];
            isOneToOne: false;
            referencedRelation: 'vaults';
            referencedColumns: ['id'];
          },
        ];
      };
      vaults: {
        Row: {
          address: string;
          closed_at: string;
          created_at: string;
          id: number;
          opened_at: string;
          status: Database['public']['Enums']['vault_status'];
          strategy_address: string;
          tenant: string | null;
          type: Database['public']['Enums']['vault_type'];
        };
        Insert: {
          address: string;
          closed_at: string;
          created_at?: string;
          id?: number;
          opened_at: string;
          status?: Database['public']['Enums']['vault_status'];
          strategy_address: string;
          tenant?: string | null;
          type?: Database['public']['Enums']['vault_type'];
        };
        Update: {
          address?: string;
          closed_at?: string;
          created_at?: string;
          id?: number;
          opened_at?: string;
          status?: Database['public']['Enums']['vault_status'];
          strategy_address?: string;
          tenant?: string | null;
          type?: Database['public']['Enums']['vault_type'];
        };
        Relationships: [
          {
            foreignKeyName: 'vaults_tenant_fkey';
            columns: ['tenant'];
            isOneToOne: false;
            referencedRelation: 'users';
            referencedColumns: ['id'];
          },
        ];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      [_ in never]: never;
    };
    Enums: {
      kyc_event: 'processing' | 'accepted' | 'rejected';
      vault_distribution_entity_types: 'activity_reward' | 'treasury' | 'vault' | 'custodian';
      vault_status: 'created' | 'ready' | 'matured';
      vault_type: 'fixed_yield';
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
}

export type Tables<
  PublicTableNameOrOptions extends
    | keyof (Database['public']['Tables'] & Database['public']['Views'])
    | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof (Database[PublicTableNameOrOptions['schema']]['Tables'] &
        Database[PublicTableNameOrOptions['schema']]['Views'])
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? (Database[PublicTableNameOrOptions['schema']]['Tables'] &
      Database[PublicTableNameOrOptions['schema']]['Views'])[TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : PublicTableNameOrOptions extends keyof (Database['public']['Tables'] & Database['public']['Views'])
    ? (Database['public']['Tables'] & Database['public']['Views'])[PublicTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  PublicTableNameOrOptions extends keyof Database['public']['Tables'] | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions['schema']]['Tables']
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : PublicTableNameOrOptions extends keyof Database['public']['Tables']
    ? Database['public']['Tables'][PublicTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  PublicTableNameOrOptions extends keyof Database['public']['Tables'] | { schema: keyof Database },
  TableName extends PublicTableNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicTableNameOrOptions['schema']]['Tables']
    : never = never,
> = PublicTableNameOrOptions extends { schema: keyof Database }
  ? Database[PublicTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : PublicTableNameOrOptions extends keyof Database['public']['Tables']
    ? Database['public']['Tables'][PublicTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  PublicEnumNameOrOptions extends keyof Database['public']['Enums'] | { schema: keyof Database },
  EnumName extends PublicEnumNameOrOptions extends { schema: keyof Database }
    ? keyof Database[PublicEnumNameOrOptions['schema']]['Enums']
    : never = never,
> = PublicEnumNameOrOptions extends { schema: keyof Database }
  ? Database[PublicEnumNameOrOptions['schema']]['Enums'][EnumName]
  : PublicEnumNameOrOptions extends keyof Database['public']['Enums']
    ? Database['public']['Enums'][PublicEnumNameOrOptions]
    : never;
