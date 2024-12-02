public with sharing class OpportunityTriggerHandler {

    /**
     * Handles post-update operations for Opportunities.
     * Creates Asset records for Opportunities updated to 'Closed Won'.
     */
    public static void handleAfterUpdate(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {
        // Filter Opportunities that transitioned to 'Closed Won'
        Set<Id> closedWonOpportunityIds = new Set<Id>();
        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOpportunities.get(opp.Id);
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                closedWonOpportunityIds.add(opp.Id);
            }
        }

        // Fetch OpportunityLineItems for these Opportunities
        Map<Id, List<OpportunityLineItem>> oppLineItemsMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT OpportunityId, Product2Id, Quantity, TotalPrice, Product2.Name, Opportunity.Account.Name
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :closedWonOpportunityIds
        ]) {
            if (!oppLineItemsMap.containsKey(oli.OpportunityId)) {
                oppLineItemsMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            oppLineItemsMap.get(oli.OpportunityId).add(oli);
        }

        // Create Assets for each OpportunityLineItem
        List<Asset> assetsToCreate = new List<Asset>();
        for (Id oppId : closedWonOpportunityIds) {
            List<OpportunityLineItem> lineItems = oppLineItemsMap.get(oppId);
            if (lineItems != null && !lineItems.isEmpty()) {
                for (OpportunityLineItem oli : lineItems) {
                    assetsToCreate.add(createAssetFromLineItem(oli));
                }
            } else {
                // Log or handle cases where there are no OpportunityLineItems
                System.debug('No OpportunityLineItems found for Opportunity Id: ' + oppId);
            }
        }

        // Insert Assets and handle errors
        if (!assetsToCreate.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(assetsToCreate, false);
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error creating Asset: ' + error.getMessage());
                        // Optionally log errors to a custom object or system
                    }
                }
            }
        }

        // Create Orders for Opportunities updated to 'Closed Won'
        createOrdersForClosedWonOpportunities(closedWonOpportunityIds);
    }

    /**
     * Creates an Asset record based on an OpportunityLineItem.
     * @param lineItem The OpportunityLineItem record
     * @return The created Asset record
     */
    private static Asset createAssetFromLineItem(OpportunityLineItem lineItem) {
        Asset newAsset = new Asset();
        String assetName = lineItem.Opportunity.Account.Name + ' - ' + lineItem.Product2.Name;
        if (assetName.length() > 255) {
            assetName = assetName.substring(0, 255);
        }
        newAsset.Name = assetName;
        newAsset.AccountId = lineItem.Opportunity.AccountId; 
        newAsset.Product2Id = lineItem.Product2Id;
        newAsset.Quantity = lineItem.Quantity;
        newAsset.Price = lineItem.TotalPrice;
        newAsset.PurchaseDate = Date.today();
        return newAsset;
    }

    /**
     * Creates Orders for Opportunities updated to 'Closed Won'.
     * @param closedWonOpportunityIds Set of Opportunity IDs
     */
    private static void createOrdersForClosedWonOpportunities(Set<Id> closedWonOpportunityIds) {
        List<Order> ordersToCreate = new List<Order>();

        // Query relevant data from Opportunities and their related objects
        List<Opportunity> opportunities = [
            SELECT Id, AccountId, Account.Name, contactId, SyncedQuoteId,SyncedQuote.ContractId

            FROM Opportunity
            WHERE Id IN :closedWonOpportunityIds
        ];

        for (Opportunity opp : opportunities) {
            Order newOrder = new Order();
            newOrder.AccountId = opp.AccountId;
            newOrder.Status = 'Draft';
            newOrder.EffectiveDate = Date.today();

            // Fetch Contract from Synced Quote
            if (opp.SyncedQuoteId != null) {
                newOrder.ContractId = opp.SyncedQuote.ContractId;
            }

            // Set BillTo and ShipTo Contacts
            if (opp.ContactId != null) {
                newOrder.BillToContactId = opp.contactID;
                newOrder.ShipToContactId = opp.contactID;
            }

            ordersToCreate.add(newOrder);
        }

        // Insert Orders and handle errors
        if (!ordersToCreate.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(ordersToCreate, false);
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error creating Order: ' + error.getMessage());
                        // Optionally log errors to a custom object or system
                    }
                }
            }
        }
    }
}