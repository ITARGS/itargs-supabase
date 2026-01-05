#!/bin/bash

# ============================================================================
# Add Missing Table Types to Supabase Types File
# ============================================================================
# This script adds the missing product_performance_tiers and product_workloads
# table definitions to the Supabase types file
# ============================================================================

set -e

echo "🔧 Adding missing table types to Supabase types file..."

TYPES_FILE="/Users/meflm/Desktop/itargs-training/itargs-supabase/ecommerce_website_reactjs/src/integrations/supabase/types.ts"

# Backup the original file
echo "💾 Creating backup..."
cp "$TYPES_FILE" "${TYPES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Add the missing table types
echo "📝 Adding missing table definitions..."

cat >> "$TYPES_FILE" << 'ENDTYPES'

// ============================================================================
// MANUALLY ADDED TYPES FOR MISSING TABLES
// ============================================================================
// These types were added to fix TypeScript errors related to
// product_performance_tiers and product_workloads relationships
// ============================================================================

export interface ProductPerformanceTier {
  id: string;
  product_id: string;
  performance_tier_id: string;
  created_at: string;
}

export interface ProductWorkload {
  id: string;
  product_id: string;
  workload_type_id: string;
  created_at: string;
}

export interface PerformanceTier {
  id: string;
  name: string;
  name_ar?: string;
  description?: string;
  description_ar?: string;
  display_order?: number;
  created_at: string;
  updated_at: string;
}

export interface WorkloadType {
  id: string;
  name: string;
  name_ar?: string;
  description?: string;
  description_ar?: string;
  icon?: string;
  display_order?: number;
  created_at: string;
  updated_at: string;
}

// Extend the Database interface to include these tables
declare module './types' {
  interface Database {
    public: {
      Tables: {
        product_performance_tiers: {
          Row: ProductPerformanceTier;
          Insert: Omit<ProductPerformanceTier, 'id' | 'created_at'>;
          Update: Partial<Omit<ProductPerformanceTier, 'id' | 'created_at'>>;
        };
        product_workloads: {
          Row: ProductWorkload;
          Insert: Omit<ProductWorkload, 'id' | 'created_at'>;
          Update: Partial<Omit<ProductWorkload, 'id' | 'created_at'>>;
        };
        performance_tiers: {
          Row: PerformanceTier;
          Insert: Omit<PerformanceTier, 'id' | 'created_at' | 'updated_at'>;
          Update: Partial<Omit<PerformanceTier, 'id' | 'created_at' | 'updated_at'>>;
        };
        workload_types: {
          Row: WorkloadType;
          Insert: Omit<WorkloadType, 'id' | 'created_at' | 'updated_at'>;
          Update: Partial<Omit<WorkloadType, 'id' | 'created_at' | 'updated_at'>>;
        };
      };
    };
  }
}

ENDTYPES

echo "✅ Missing types added successfully!"
echo ""
echo "📋 Added types for:"
echo "  ✅ product_performance_tiers"
echo "  ✅ product_workloads"
echo "  ✅ performance_tiers"
echo "  ✅ workload_types"
echo ""
echo "💾 Backup created at: ${TYPES_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo ""
echo "🔄 Now you can restore the relationships in useProducts.ts if needed"
echo ""
