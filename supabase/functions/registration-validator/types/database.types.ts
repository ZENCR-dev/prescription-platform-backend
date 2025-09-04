export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  graphql_public: {
    Tables: {
      [_ in never]: never;
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      graphql: {
        Args: {
          extensions?: Json;
          operationName?: string;
          query?: string;
          variables?: Json;
        };
        Returns: Json;
      };
    };
    Enums: {
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
  public: {
    Tables: {
      fulfillment_credentials: {
        Row: {
          created_at: string | null;
          credential_type: string;
          id: string;
          notes: string | null;
          order_id: string | null;
          pharmacy_id: string;
        };
        Insert: {
          created_at?: string | null;
          credential_type: string;
          id?: string;
          notes?: string | null;
          order_id?: string | null;
          pharmacy_id: string;
        };
        Update: {
          created_at?: string | null;
          credential_type?: string;
          id?: string;
          notes?: string | null;
          order_id?: string | null;
          pharmacy_id?: string;
        };
        Relationships: [
          {
            foreignKeyName: 'fulfillment_credentials_order_id_fkey';
            columns: ['order_id'];
            isOneToOne: false;
            referencedRelation: 'orders';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'fulfillment_credentials_pharmacy_id_fkey';
            columns: ['pharmacy_id'];
            isOneToOne: false;
            referencedRelation: 'pharmacies';
            referencedColumns: ['id'];
          },
        ];
      };
      inventory_tracking: {
        Row: {
          id: string;
          item_code: string;
          last_updated: string | null;
          pharmacy_id: string;
          quantity: number | null;
          status: string | null;
        };
        Insert: {
          id?: string;
          item_code: string;
          last_updated?: string | null;
          pharmacy_id: string;
          quantity?: number | null;
          status?: string | null;
        };
        Update: {
          id?: string;
          item_code?: string;
          last_updated?: string | null;
          pharmacy_id?: string;
          quantity?: number | null;
          status?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'inventory_tracking_pharmacy_id_fkey';
            columns: ['pharmacy_id'];
            isOneToOne: false;
            referencedRelation: 'pharmacies';
            referencedColumns: ['id'];
          },
        ];
      };
      orders: {
        Row: {
          assigned_pharmacy_id: string | null;
          created_at: string | null;
          id: string;
          patient_id: string | null;
          status: string | null;
          total_amount_cents: number;
          updated_at: string | null;
        };
        Insert: {
          assigned_pharmacy_id?: string | null;
          created_at?: string | null;
          id?: string;
          patient_id?: string | null;
          status?: string | null;
          total_amount_cents?: number;
          updated_at?: string | null;
        };
        Update: {
          assigned_pharmacy_id?: string | null;
          created_at?: string | null;
          id?: string;
          patient_id?: string | null;
          status?: string | null;
          total_amount_cents?: number;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'orders_assigned_pharmacy_id_fkey';
            columns: ['assigned_pharmacy_id'];
            isOneToOne: false;
            referencedRelation: 'pharmacies';
            referencedColumns: ['id'];
          },
        ];
      };
      patient_records: {
        Row: {
          created_at: string | null;
          email: string | null;
          first_name: string | null;
          id: string;
          last_name: string | null;
        };
        Insert: {
          created_at?: string | null;
          email?: string | null;
          first_name?: string | null;
          id: string;
          last_name?: string | null;
        };
        Update: {
          created_at?: string | null;
          email?: string | null;
          first_name?: string | null;
          id?: string;
          last_name?: string | null;
        };
        Relationships: [];
      };
      pharmacies: {
        Row: {
          contact_info: Json | null;
          created_at: string | null;
          id: string;
          name: string;
          status: string | null;
          updated_at: string | null;
        };
        Insert: {
          contact_info?: Json | null;
          created_at?: string | null;
          id?: string;
          name: string;
          status?: string | null;
          updated_at?: string | null;
        };
        Update: {
          contact_info?: Json | null;
          created_at?: string | null;
          id?: string;
          name?: string;
          status?: string | null;
          updated_at?: string | null;
        };
        Relationships: [];
      };
      po_settlements: {
        Row: {
          created_at: string | null;
          id: string;
          order_id: string | null;
          pharmacy_id: string;
          settlement_amount_cents: number;
          status: string | null;
        };
        Insert: {
          created_at?: string | null;
          id?: string;
          order_id?: string | null;
          pharmacy_id: string;
          settlement_amount_cents?: number;
          status?: string | null;
        };
        Update: {
          created_at?: string | null;
          id?: string;
          order_id?: string | null;
          pharmacy_id?: string;
          settlement_amount_cents?: number;
          status?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'po_settlements_order_id_fkey';
            columns: ['order_id'];
            isOneToOne: false;
            referencedRelation: 'orders';
            referencedColumns: ['id'];
          },
          {
            foreignKeyName: 'po_settlements_pharmacy_id_fkey';
            columns: ['pharmacy_id'];
            isOneToOne: false;
            referencedRelation: 'pharmacies';
            referencedColumns: ['id'];
          },
        ];
      };
      user_profiles: {
        Row: {
          business_info: Json | null;
          created_at: string | null;
          id: string;
          pharmacy_id: string | null;
          role: string;
          status: string | null;
          updated_at: string | null;
        };
        Insert: {
          business_info?: Json | null;
          created_at?: string | null;
          id: string;
          pharmacy_id?: string | null;
          role: string;
          status?: string | null;
          updated_at?: string | null;
        };
        Update: {
          business_info?: Json | null;
          created_at?: string | null;
          id?: string;
          pharmacy_id?: string | null;
          role?: string;
          status?: string | null;
          updated_at?: string | null;
        };
        Relationships: [
          {
            foreignKeyName: 'user_profiles_pharmacy_id_fkey';
            columns: ['pharmacy_id'];
            isOneToOne: false;
            referencedRelation: 'pharmacies';
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
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>;

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, 'public'>];

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema['Tables']
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Row: infer R;
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Row: infer R;
      }
      ? R
      : never
    : never;

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema['Tables']
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Insert: infer I;
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I;
      }
      ? I
      : never
    : never;

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema['Tables']
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables']
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions['schema']]['Tables'][TableName] extends {
      Update: infer U;
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema['Tables']
    ? DefaultSchema['Tables'][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U;
      }
      ? U
      : never
    : never;

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema['Enums']
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums']
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions['schema']]['Enums'][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema['Enums']
    ? DefaultSchema['Enums'][DefaultSchemaEnumNameOrOptions]
    : never;

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema['CompositeTypes']
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals;
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes']
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals;
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions['schema']]['CompositeTypes'][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema['CompositeTypes']
    ? DefaultSchema['CompositeTypes'][PublicCompositeTypeNameOrOptions]
    : never;

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const;
