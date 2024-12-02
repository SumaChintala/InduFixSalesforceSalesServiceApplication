@isTest
public class TestOpportunityTriggerHandler {

    @isTest
    static void testHandleAfterUpdate() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        // Use Test.getStandardPricebookId() to fetch the standard pricebook ID
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create a standard pricebook entry for the product
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPricebookEntry;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id);
        insert testContact;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            ContactId = testContact.Id
        );
        insert testOpportunity;

        // Create and insert a Quote for the Opportunity
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Status = 'Accepted'
        );
        insert testQuote;
        
        testOpportunity.SyncedQuoteId = testQuote.ID;
        Update testOpportunity;

        OpportunityLineItem testOLI = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = standardPricebookEntry.Id,
            Quantity = 1,
            TotalPrice = 100
        );
        insert testOLI;

        // Update Opportunity to 'Engineering Review'
        testOpportunity.StageName = 'Engineering Review';
        update testOpportunity;
        
        // Update Opportunity to 'Manufacturing Preparation'
        testOpportunity.StageName = 'Manufacturing Preparation';
        update testOpportunity;
        
        // Update Opportunity to Closed Won
        testOpportunity.StageName = 'Closed Won';
        update testOpportunity;

        // Validate Assets
        List<Asset> createdAssets = [SELECT Name, AccountId, Product2Id, Quantity, Price, PurchaseDate FROM Asset];
        System.assertEquals(1, createdAssets.size(), 'One Asset should have been created.');
        Asset createdAsset = createdAssets[0];
        System.assertEquals(testAccount.Id, createdAsset.AccountId, 'Asset AccountId should match Opportunity AccountId.');
        System.assertEquals(testProduct.Id, createdAsset.Product2Id, 'Asset Product2Id should match OpportunityLineItem Product2Id.');

        // Validate Order
        List<Order> createdOrders = [SELECT AccountId, Status, EffectiveDate, BillToContactId, ShipToContactId, ContractId FROM Order];
        System.assertEquals(1, createdOrders.size(), 'One Order should have been created.');
        Order createdOrder = createdOrders[0];
        System.assertEquals(testAccount.Id, createdOrder.AccountId, 'Order AccountId should match Opportunity AccountId.');
        System.assertEquals('Draft', createdOrder.Status, 'Order Status should be Draft.');
        System.assertEquals(testContact.Id, createdOrder.BillToContactId, 'Order BillToContactId should match Opportunity ContactId.');
        System.assertEquals(testContact.Id, createdOrder.ShipToContactId, 'Order ShipToContactId should match Opportunity ContactId.');

        // Validate no errors occurred
        System.assertNotEquals(null, createdOrder.EffectiveDate, 'Order EffectiveDate should not be null.');
    }
}