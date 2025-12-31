#!/bin/bash
# Fix RTL for customer pages - replace mr- with me- and ml- with ms-

FILES=(
  "src/pages/Account.tsx"
  "src/pages/OrderSuccess.tsx"
  "src/pages/Checkout.tsx"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Processing: $file"
    # Replace mr- with me- (margin-right to margin-end)
    sed -i '' 's/className="\([^"]*\)mr-\([0-9]\)/className="\1me-\2/g' "$file"
    sed -i '' "s/className='\([^']*\)mr-\([0-9]\)/className='\1me-\2/g" "$file"
    
    # Replace ml- with ms- (margin-left to margin-start)
    sed -i '' 's/className="\([^"]*\)ml-\([0-9]\)/className="\1ms-\2/g' "$file"
    sed -i '' "s/className='\([^']*\)ml-\([0-9]\)/className='\1ms-\2/g" "$file"
    
    # Replace pl- with ps- (padding-left to padding-start)
    sed -i '' 's/className="\([^"]*\)pl-\([0-9]\)/className="\1ps-\2/g' "$file"
    sed -i '' "s/className='\([^']*\)pl-\([0-9]\)/className='\1ps-\2/g" "$file"
    
    # Replace pr- with pe- (padding-right to padding-end)
    sed -i '' 's/className="\([^"]*\)pr-\([0-9]\)/className="\1pe-\2/g' "$file"
    sed -i '' "s/className='\([^']*\)pr-\([0-9]\)/className='\1pe-\2/g" "$file"
    
    # Replace text-left with text-start
    sed -i '' 's/text-left/text-start/g' "$file"
    
    # Replace text-right with text-end
    sed -i '' 's/text-right/text-end/g' "$file"
  fi
done

echo "✅ Phase 1 Complete: Customer pages RTL fixed"
