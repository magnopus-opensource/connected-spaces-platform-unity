%{
#include "CSP/Systems/ECommerce/ECommerce.h"
%}

ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::CurrencyInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ProductMediaInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::VariantOptionInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ProductVariantInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ProductInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::CheckoutInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::CartLine)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::CartInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ShopifyStoreInfo)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ProductInfoResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ProductInfoCollectionResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::CheckoutInfoResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::CartInfoResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::AddShopifyStoreResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::GetShopifyStoresResult)
ADD_OUTER_OBJECT_PIN_SLOT(csp::systems::ValidateShopifyStoreResult)

%include "CSP/Systems/ECommerce/ECommerce.h"
