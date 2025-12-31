#!/bin/bash
# Batch script to remove ShopHeader from customer pages

FILES=(
  "src/pages/Account.tsx"
  "src/pages/Contact.tsx"
  "src/pages/FAQ.tsx"
  "src/pages/LearningArticle.tsx"
  "src/pages/LearningHub.tsx"
  "src/pages/OrderSuccess.tsx"
  "src/pages/Privacy.tsx"
  "src/pages/Shipping.tsx"
  "src/pages/Terms.tsx"
  "src/pages/Wishlist.tsx"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Processing: $file"
    # Remove import line
    sed -i '' '/import.*ShopHeader.*from.*@\/components\/shop\/ShopHeader/d' "$file"
    # Remove usage lines
    sed -i '' '/<ShopHeader \/>/d' "$file"
  fi
done

echo "Cleanup complete!"
